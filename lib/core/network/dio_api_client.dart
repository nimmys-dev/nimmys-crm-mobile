// Dio ships its own `ProgressCallback` with the same shape as ours. Hiding it
// keeps the transport-agnostic one from `api_client.dart` as the single name
// in scope, so the signatures here match the interface exactly.
import 'package:dio/dio.dart' hide ProgressCallback;

import '../error/app_exception.dart';
import '../session/session_manager.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'api_response.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'request_keys.dart';
import 'response_envelope.dart';

/// The Dio-backed [ApiClient].
///
/// This is the only file in the app that imports Dio for request work. Every
/// verb funnels through [_send], so envelope unwrapping, parsing and error
/// translation are written once rather than per method — the thing that keeps
/// a data source down to a single readable line per endpoint.
class DioApiClient implements ApiClient {
  DioApiClient({
    required Dio dio,
    required ApiConfig config,
    ResponseEnvelope envelope = const WrappedEnvelope(),
  }) : _dio = dio,
       _config = config,
       _envelope = envelope;

  /// Assembles a fully wired client.
  ///
  /// Interceptor order is load-bearing, and Dio runs them in registration
  /// order for requests *and* errors:
  ///
  /// 1. **Auth** — attaches the token on the way out; on a 401 it refreshes
  ///    and replays before anything else sees the failure.
  /// 2. **Retry** — handles the transient failures auth could not fix.
  /// 3. **Logging** — records the final outcome, after any recovery, so the
  ///    log shows what actually happened rather than every internal attempt.
  /// 4. **Error** — maps to [AppException] last, once the failure is final.
  factory DioApiClient.create({
    required ApiConfig config,
    required SessionManager session,
    ResponseEnvelope envelope = const WrappedEnvelope(),
  }) {
    final BaseOptions options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, dynamic>{'Accept': 'application/json'},
      // Non-2xx is routed to the error path rather than throwing raw, so the
      // error interceptor is the single place that classifies status codes.
      validateStatus: (int? status) => status != null && status >= 200 && status < 300,
    );

    final Dio dio = Dio(options);

    // Bare client for the refresh call and for replaying a request after a
    // refresh. It shares the base options but carries no auth interceptor,
    // which is what stops a 401 on refresh from recursing forever.
    final Dio refreshClient = Dio(options);

    dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(
        session: session,
        refreshClient: refreshClient,
        refreshPath: Endpoints.refreshToken,
      ),
      RetryInterceptor(config: config),
      if (config.enableLogging) LoggingInterceptor(),
      ErrorInterceptor(envelope: envelope),
    ]);

    // The refresh client still needs error mapping so a failed refresh
    // surfaces as an AppException rather than a raw DioException.
    refreshClient.interceptors.add(ErrorInterceptor(envelope: envelope));

    return DioApiClient(dio: dio, config: config, envelope: envelope);
  }

  final Dio _dio;
  final ApiConfig _config;
  final ResponseEnvelope _envelope;

  /// Exposed for the rare case needing raw access (streamed downloads, a
  /// third-party SDK that wants a configured Dio). Prefer the typed methods.
  Dio get raw => _dio;

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config = const RequestConfig(),
    ApiCancelToken? cancelToken,
  }) => _send<T>(
    'GET',
    path,
    queryParameters: queryParameters,
    parser: parser,
    config: config,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config = const RequestConfig(),
    ApiCancelToken? cancelToken,
  }) => _send<T>(
    'POST',
    path,
    body: body,
    queryParameters: queryParameters,
    parser: parser,
    config: config,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config = const RequestConfig(),
    ApiCancelToken? cancelToken,
  }) => _send<T>(
    'PUT',
    path,
    body: body,
    queryParameters: queryParameters,
    parser: parser,
    config: config,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config = const RequestConfig(),
    ApiCancelToken? cancelToken,
  }) => _send<T>(
    'PATCH',
    path,
    body: body,
    queryParameters: queryParameters,
    parser: parser,
    config: config,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    RequestConfig config = const RequestConfig(),
    ApiCancelToken? cancelToken,
  }) => _send<T>(
    'DELETE',
    path,
    body: body,
    queryParameters: queryParameters,
    parser: parser,
    config: config,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required List<UploadFile> files,
    Map<String, dynamic> fields = const <String, dynamic>{},
    ResponseParser<T>? parser,
    RequestConfig config = const RequestConfig(),
    ApiCancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      ...fields,
      for (final UploadFile file in files)
        file.field: await MultipartFile.fromFile(
          file.path,
          filename: file.filename,
          contentType: file.contentType == null
              ? null
              : DioMediaType.parse(file.contentType!),
        ),
    });

    return _send<T>(
      'POST',
      path,
      body: form,
      parser: parser,
      // An upload is never idempotent — replaying it duplicates the file.
      config: config.copyWith(allowRetry: false),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  @override
  Future<void> download(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    RequestConfig config = const RequestConfig(),
    ApiCancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        cancelToken: _adapt(cancelToken),
        options: _optionsFor('GET', config),
        onReceiveProgress: onReceiveProgress == null
            ? null
            : (int received, int total) => onReceiveProgress(received, total),
      );
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  // ------------------------------------------------------------------- Core

  Future<ApiResponse<T>> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    ResponseParser<T>? parser,
    required RequestConfig config,
    ApiCancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final Response<dynamic> response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        cancelToken: _adapt(cancelToken),
        options: _optionsFor(method, config),
        onSendProgress: onSendProgress == null
            ? null
            : (int sent, int total) => onSendProgress(sent, total),
      );
      return _decode<T>(response, parser, config);
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  Options _optionsFor(String method, RequestConfig config) => Options(
    method: method,
    headers: config.headers.isEmpty ? null : config.headers,
    sendTimeout: config.sendTimeout ?? _config.sendTimeout,
    receiveTimeout: config.receiveTimeout ?? _config.receiveTimeout,
    extra: <String, dynamic>{
      RequestKeys.requiresAuth: config.requiresAuth,
      if (config.allowRetry != null) RequestKeys.allowRetry: config.allowRetry,
    },
    validateStatus: config.expectedStatusCodes == null
        ? null
        : (int? status) =>
              status != null &&
              (status >= 200 && status < 300 ||
                  config.expectedStatusCodes!.contains(status)),
  );

  /// Unwraps the envelope and runs [parser].
  ///
  /// Parse failures become [ParseException] rather than escaping as a raw
  /// `TypeError`: a contract change on the server should surface as a handled
  /// error state, not a red screen.
  ApiResponse<T> _decode<T>(
    Response<dynamic> response,
    ResponseParser<T>? parser,
    RequestConfig config,
  ) {
    final dynamic body = response.data;
    final int status = response.statusCode ?? 0;

    // Some APIs answer 200 with `{"success": false}`. Without this check that
    // reads as a successful empty result and the user sees nothing wrong.
    if (!_envelope.isSuccess(body)) {
      final Map<String, List<String>> fields = _envelope.extractFieldErrors(body);
      final String? message = _envelope.extractMessage(body);
      throw fields.isEmpty
          ? ServerException(
              message: message ?? 'The server reported a failure.',
              statusCode: status,
            )
          : ValidationException(
              message: message ?? 'The server rejected the request.',
              statusCode: status,
              fieldErrors: fields,
              serverMessage: message,
            );
    }

    // A paginated call opts out so its parser can reach `meta` alongside the
    // rows; everything else gets the payload it actually asked for.
    final dynamic payload = config.unwrapEnvelope
        ? _envelope.extractData(body)
        : body;

    try {
      return ApiResponse<T>(
        data: parser != null ? parser(payload) : payload as T,
        statusCode: status,
        message: _envelope.extractMessage(body),
        headers: response.headers.map,
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      throw ParseException(
        message:
            'Could not parse ${response.requestOptions.uri} as $T: $error',
        statusCode: status,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Bridges the transport-agnostic token to Dio's own.
  CancelToken? _adapt(ApiCancelToken? token) {
    if (token == null) {
      return null;
    }
    final CancelToken dioToken = CancelToken();
    if (token.isCancelled) {
      dioToken.cancel();
      return dioToken;
    }
    // ignore: discarded_futures — fire-and-forget bridge, nothing to await.
    token.whenCancelled.then(dioToken.cancel);
    return dioToken;
  }

  /// Pulls out the [AppException] the error interceptor attached.
  ///
  /// The fallback covers a Dio instance built without that interceptor, so
  /// this method is always safe to call.
  AppException _unwrap(DioException error) {
    final Object? mapped = error.error;
    if (mapped is AppException) {
      return mapped;
    }
    return UnknownException(
      message: error.message ?? error.toString(),
      statusCode: error.response?.statusCode,
      cause: error,
      stackTrace: error.stackTrace,
    );
  }
}
