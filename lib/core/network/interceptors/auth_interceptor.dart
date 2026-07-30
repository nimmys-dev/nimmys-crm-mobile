import 'dart:async';

import 'package:dio/dio.dart';

import '../../session/session_manager.dart';
import '../../storage/auth_tokens.dart';
import '../request_keys.dart';

/// Attaches the bearer token and transparently recovers from an expired one.
///
/// The hard part is concurrency. A dashboard opening four requests at once
/// will see four simultaneous 401s, and the naive implementation fires four
/// refreshes — three of which use an already-rotated refresh token and fail,
/// signing the user out mid-session. The single-flight guard below collapses
/// those into one refresh that every waiting request shares.
///
/// Deliberately a plain [Interceptor] rather than a `QueuedInterceptor`:
/// queueing would serialise *every* request through this interceptor, not just
/// the refresh, throttling normal traffic to fix a problem only refresh has.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionManager session,
    required Dio refreshClient,
    required String refreshPath,
    this.proactiveRefresh = true,
  }) : _session = session,
       _refreshClient = refreshClient,
       _refreshPath = refreshPath;

  final SessionManager _session;

  /// A Dio instance that does **not** carry this interceptor.
  ///
  /// Refreshing through the main client would send the refresh call back
  /// through here; if it 401s, that triggers another refresh, and so on until
  /// the stack overflows.
  final Dio _refreshClient;

  final String _refreshPath;

  /// Whether to refresh just before expiry instead of waiting for a 401.
  /// Saves the user a doubled round trip on the first request after a token
  /// goes stale.
  final bool proactiveRefresh;

  /// The refresh currently in flight, if any. This single field is what makes
  /// the whole thing safe under concurrency.
  Future<AuthTokens?>? _inFlightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[RequestKeys.requiresAuth] == false) {
      return handler.next(options);
    }

    AuthTokens? tokens = _session.tokens;

    if (tokens != null &&
        proactiveRefresh &&
        tokens.hasRefreshToken &&
        tokens.needsRefresh()) {
      tokens = await _refreshOnce() ?? tokens;
    }

    if (tokens != null) {
      options.headers['Authorization'] = tokens.authorizationHeader;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions options = err.requestOptions;

    final bool canAttemptRefresh =
        err.response?.statusCode == 401 &&
        options.extra[RequestKeys.requiresAuth] != false &&
        // Without this guard a request whose retry also 401s would loop.
        options.extra[RequestKeys.didRetryAfterRefresh] != true &&
        (_session.tokens?.hasRefreshToken ?? false);

    if (!canAttemptRefresh) {
      // A 401 we cannot recover from means the session is genuinely over.
      if (err.response?.statusCode == 401 &&
          options.extra[RequestKeys.requiresAuth] != false) {
        await _session.signOut(reason: SessionEndReason.expired);
      }
      return handler.next(err);
    }

    final AuthTokens? refreshed = await _refreshOnce();
    if (refreshed == null) {
      await _session.signOut(reason: SessionEndReason.expired);
      return handler.next(err);
    }

    try {
      handler.resolve(await _replay(options, refreshed));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Returns the in-flight refresh if one is running, otherwise starts one.
  ///
  /// Callers all await the same future, so N concurrent 401s spend exactly
  /// one refresh token.
  Future<AuthTokens?> _refreshOnce() {
    final Future<AuthTokens?>? existing = _inFlightRefresh;
    if (existing != null) {
      return existing;
    }

    final Future<AuthTokens?> refresh = _performRefresh();
    _inFlightRefresh = refresh;

    // Cleared only if still the current attempt, so a refresh that starts
    // while this one is settling is not wiped out by the loser's cleanup.
    unawaited(
      refresh.whenComplete(() {
        if (identical(_inFlightRefresh, refresh)) {
          _inFlightRefresh = null;
        }
      }),
    );

    return refresh;
  }

  Future<AuthTokens?> _performRefresh() async {
    final String? refreshToken = _session.tokens?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final Response<dynamic> response = await _refreshClient.post<dynamic>(
        _refreshPath,
        data: <String, dynamic>{'refresh_token': refreshToken},
      );

      final dynamic body = response.data;
      final Map<String, dynamic> payload = switch (body) {
        // Tolerates both a bare token object and one wrapped in `data`.
        {'data': final Map<String, dynamic> data} => data,
        final Map<String, dynamic> map => map,
        _ => const <String, dynamic>{},
      };

      if (payload.isEmpty) {
        return null;
      }

      final AuthTokens tokens = AuthTokens.fromJson(payload);
      // Servers that do not rotate the refresh token omit it from the
      // response; keeping the old one prevents losing it on those APIs.
      final AuthTokens merged = tokens.hasRefreshToken
          ? tokens
          : tokens.copyWith(refreshToken: refreshToken);

      await _session.onTokensRefreshed(merged);
      return merged;
    } catch (_) {
      // Any failure here — network, 401, malformed body — means we cannot
      // recover the session. The caller signs the user out.
      return null;
    }
  }

  /// Re-sends the original request with the new token.
  Future<Response<dynamic>> _replay(
    RequestOptions options,
    AuthTokens tokens,
  ) {
    options.headers['Authorization'] = tokens.authorizationHeader;
    options.extra = <String, dynamic>{
      ...options.extra,
      RequestKeys.didRetryAfterRefresh: true,
    };
    return _refreshClient.fetch<dynamic>(options);
  }
}
