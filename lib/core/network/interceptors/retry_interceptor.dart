import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../api_config.dart';
import '../request_keys.dart';

/// Re-sends requests that failed for reasons likely to be temporary.
///
/// Two rules keep this from doing damage:
///
/// 1. Only *idempotent* verbs are replayed by default. Retrying a POST that
///    actually reached the server and timed out on the way back creates a
///    second lead from one tap; a request opts in explicitly via
///    `RequestConfig.allowRetry` when the endpoint is safe.
/// 2. 4xx responses are never retried — the server understood and refused,
///    and asking again changes nothing. The exception is 429, which is an
///    explicit "ask again later".
///
/// Backoff is exponential with jitter. Without jitter, every client knocked
/// offline by the same server blip retries in lockstep and hits it again as a
/// synchronised wave.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required ApiConfig config, Random? random})
    : _config = config,
      _random = random ?? Random();

  static const Set<String> _idempotentMethods = <String>{
    'GET',
    'HEAD',
    'OPTIONS',
    'PUT',
    'DELETE',
  };

  final ApiConfig _config;
  final Random _random;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions options = err.requestOptions;
    final int attempt = (options.extra[RequestKeys.retryCount] as int?) ?? 0;

    if (attempt >= _config.maxRetries || !_shouldRetry(err)) {
      return handler.next(err);
    }

    await Future<void>.delayed(_delayFor(attempt, err));

    // A token cancelled while we were waiting out the backoff — abandon
    // rather than firing a request nobody is listening for.
    if (options.cancelToken?.isCancelled ?? false) {
      return handler.next(err);
    }

    options.extra = <String, dynamic>{
      ...options.extra,
      RequestKeys.retryCount: attempt + 1,
    };

    try {
      handler.resolve(await Dio(_baseOptions(options)).fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRetry(DioException err) {
    final bool? explicit =
        err.requestOptions.extra[RequestKeys.allowRetry] as bool?;
    if (explicit == false) {
      return false;
    }

    final bool methodAllows =
        explicit ?? _idempotentMethods.contains(err.requestOptions.method.toUpperCase());
    if (!methodAllows) {
      return false;
    }

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => switch (err.response?.statusCode) {
        429 => true,
        final int status when status >= 500 => true,
        _ => false,
      },
      // Cancellation is a deliberate act and a bad certificate will not fix
      // itself on a second attempt.
      DioExceptionType.cancel || DioExceptionType.badCertificate => false,
      DioExceptionType.unknown => true,
    };
  }

  Duration _delayFor(int attempt, DioException err) {
    // A server that told us how long to wait outranks our own guess.
    final String? retryAfter = err.response?.headers.value('retry-after');
    final int? seconds = retryAfter == null ? null : int.tryParse(retryAfter);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }

    final int base = _config.retryBackoff.inMilliseconds * pow(2, attempt).toInt();
    // Full jitter: anywhere in [0, base] rather than always exactly base.
    return Duration(milliseconds: _random.nextInt(base + 1) + base ~/ 2);
  }

  /// Rebuilds the transport for the replay without this interceptor attached,
  /// so a retried request cannot re-enter the retry chain and multiply.
  static BaseOptions _baseOptions(RequestOptions options) => BaseOptions(
    baseUrl: options.baseUrl,
    connectTimeout: options.connectTimeout,
    sendTimeout: options.sendTimeout,
    receiveTimeout: options.receiveTimeout,
    headers: options.headers,
    responseType: options.responseType,
    contentType: options.contentType,
    validateStatus: options.validateStatus,
  );
}
