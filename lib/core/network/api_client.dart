import 'dart:async';

import 'api_response.dart';

/// The contract every data source talks to.
///
/// Nothing in this file mentions Dio. That is the point: features depend on
/// this interface, so replacing the transport with `package:http`, a gRPC
/// gateway or an in-memory fake for tests means writing one new implementation
/// and changing one line of DI registration — no feature code moves.
abstract interface class ApiClient {
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config,
    ApiCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config,
    ApiCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config,
    ApiCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config,
    ApiCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config,
    ApiCancelToken? cancelToken,
  });

  /// Multipart upload. [fields] are sent alongside the files as form data.
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required List<UploadFile> files,
    Map<String, dynamic> fields,
    ResponseParser<T>? parser,
    RequestConfig config,
    ApiCancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  });

  Future<void> download(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    RequestConfig config,
    ApiCancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });
}

/// Bytes transferred so far out of the total, or -1 when the total is unknown.
typedef ProgressCallback = void Function(int sent, int total);

/// Per-request knobs that do not belong in the URL or body.
///
/// Deliberately a value type rather than a `Map<String, dynamic>` of extras:
/// every option here is discoverable, typed and impossible to misspell.
class RequestConfig {
  const RequestConfig({
    this.requiresAuth = true,
    this.headers = const <String, String>{},
    this.connectTimeout,
    this.sendTimeout,
    this.receiveTimeout,
    this.allowRetry,
    this.expectedStatusCodes,
    this.unwrapEnvelope = true,
  });

  /// Public endpoints (login, password reset) set this to false so the auth
  /// interceptor neither attaches a token nor tries to refresh on a 401 —
  /// without it, a wrong-password 401 would trigger a pointless refresh and
  /// then a spurious forced logout.
  static const RequestConfig public = RequestConfig(requiresAuth: false);

  final bool requiresAuth;

  final Map<String, String> headers;

  /// Overrides for the [ApiConfig] defaults, for the rare endpoint that is
  /// legitimately slow (a report export) or must fail fast (a health check).
  final Duration? connectTimeout;
  final Duration? sendTimeout;
  final Duration? receiveTimeout;

  /// Forces retry on or off for this call.
  ///
  /// Null means "decide from the HTTP method" — the retry interceptor only
  /// replays idempotent verbs by default, because replaying a POST can create
  /// two leads from one tap. Set true only when the endpoint is idempotent
  /// (for example, it takes an idempotency key).
  final bool? allowRetry;

  /// Status codes to treat as success even though they are not 2xx. Useful
  /// for endpoints where a 404 is a meaningful answer rather than an error.
  final Set<int>? expectedStatusCodes;

  /// Whether the parser receives the payload or the whole response body.
  ///
  /// Unwrapping is what a parser wants almost always. The exception is a
  /// paginated list: the rows live under `data` but the page count lives
  /// beside it under `meta`, and a parser handed only the rows cannot see
  /// how many pages remain. Those calls set this false and read both.
  final bool unwrapEnvelope;

  /// For paginated list endpoints — see [unwrapEnvelope].
  static const RequestConfig paginated = RequestConfig(unwrapEnvelope: false);

  RequestConfig copyWith({
    bool? requiresAuth,
    Map<String, String>? headers,
    bool? allowRetry,
    bool? unwrapEnvelope,
  }) => RequestConfig(
    requiresAuth: requiresAuth ?? this.requiresAuth,
    headers: headers ?? this.headers,
    connectTimeout: connectTimeout,
    sendTimeout: sendTimeout,
    receiveTimeout: receiveTimeout,
    allowRetry: allowRetry ?? this.allowRetry,
    expectedStatusCodes: expectedStatusCodes,
    unwrapEnvelope: unwrapEnvelope ?? this.unwrapEnvelope,
  );
}

/// A file being uploaded, described without reference to any HTTP library.
class UploadFile {
  const UploadFile({
    required this.field,
    required this.path,
    this.filename,
    this.contentType,
  });

  /// Form field name the server expects, e.g. `avatar`.
  final String field;

  /// Absolute path on disk.
  final String path;

  final String? filename;

  /// MIME type, e.g. `image/jpeg`. Inferred from the extension when null.
  final String? contentType;
}

/// Cancels an in-flight request.
///
/// Its own type rather than Dio's `CancelToken` so cancellation stays part of
/// the transport-agnostic contract. A search field that cancels the previous
/// query on each keystroke, or a bloc that cancels on `close()`, works the
/// same whatever the implementation underneath.
class ApiCancelToken {
  final Completer<String> _completer = Completer<String>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes with the cancellation reason. Implementations listen to this
  /// to abort their own native token.
  Future<String> get whenCancelled => _completer.future;

  void cancel([String reason = 'Request cancelled by caller.']) {
    if (!_completer.isCompleted) {
      _completer.complete(reason);
    }
  }
}
