import 'package:dio/dio.dart';

import '../../error/app_exception.dart';
import '../response_envelope.dart';

/// Translates every transport failure into an [AppException].
///
/// This is the boundary where Dio stops existing as far as the rest of the
/// app is concerned. Registered last so it runs after the auth and retry
/// interceptors have had their chance to recover — only failures that are
/// genuinely final get mapped and handed upwards.
///
/// The mapped exception rides along in `DioException.error`, which
/// `DioApiClient` unwraps and rethrows. Keeping the mapping in an interceptor
/// rather than in the client means a stray `dio.get()` anywhere still produces
/// a typed error.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor({ResponseEnvelope envelope = const WrappedEnvelope()})
    : _envelope = envelope;

  final ResponseEnvelope _envelope;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Already mapped by an inner interceptor — leave it alone.
    if (err.error is AppException) {
      return handler.next(err);
    }

    handler.next(
      err.copyWith(error: _map(err), stackTrace: err.stackTrace),
    );
  }

  AppException _map(DioException err) {
    final StackTrace stackTrace = err.stackTrace;

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => RequestTimeoutException(
        message: 'Timed out calling ${err.requestOptions.uri}',
        cause: err,
        stackTrace: stackTrace,
      ),

      DioExceptionType.cancel => RequestCancelledException(
        message: 'Cancelled ${err.requestOptions.uri}',
        cause: err,
        stackTrace: stackTrace,
      ),

      DioExceptionType.connectionError => NetworkException(
        message: 'Could not reach ${err.requestOptions.uri}',
        cause: err,
        stackTrace: stackTrace,
      ),

      DioExceptionType.badCertificate => NetworkException(
        message: 'Rejected the TLS certificate for ${err.requestOptions.uri}',
        cause: err,
        stackTrace: stackTrace,
      ),

      DioExceptionType.badResponse => _mapResponse(err, stackTrace),

      DioExceptionType.unknown => _mapUnknown(err, stackTrace),
    };
  }

  /// A socket-level failure surfaces as `unknown` with a nested OS error, so
  /// check the underlying cause before giving up and calling it unknown.
  AppException _mapUnknown(DioException err, StackTrace stackTrace) {
    final String description = err.error?.toString() ?? err.message ?? '';
    final bool looksLikeSocket =
        description.contains('SocketException') ||
        description.contains('Connection closed') ||
        description.contains('Connection reset');

    if (looksLikeSocket) {
      return NetworkException(
        message: description,
        cause: err.error ?? err,
        stackTrace: stackTrace,
      );
    }

    return UnknownException(
      message: description.isEmpty ? 'Unknown request failure.' : description,
      statusCode: err.response?.statusCode,
      cause: err.error ?? err,
      stackTrace: stackTrace,
    );
  }

  AppException _mapResponse(DioException err, StackTrace stackTrace) {
    final Response<dynamic>? response = err.response;
    final int status = response?.statusCode ?? 0;
    final dynamic body = response?.data;

    final String? serverMessage = _safely(() => _envelope.extractMessage(body));
    final String message =
        serverMessage ?? 'HTTP $status for ${err.requestOptions.uri}';

    return switch (status) {
      400 => _asValidation(body, status, message, err, stackTrace),
      401 => UnauthorizedException(
        message: message,
        cause: err,
        stackTrace: stackTrace,
      ),
      403 => ForbiddenException(
        message: message,
        cause: err,
        stackTrace: stackTrace,
      ),
      404 => NotFoundException(
        message: message,
        cause: err,
        stackTrace: stackTrace,
      ),
      409 => ConflictException(
        message: message,
        serverMessage: serverMessage,
        cause: err,
        stackTrace: stackTrace,
      ),
      422 => _asValidation(body, status, message, err, stackTrace),
      429 => RateLimitException(
        message: message,
        retryAfter: _retryAfter(response),
        cause: err,
        stackTrace: stackTrace,
      ),
      >= 500 => ServerException(
        message: message,
        statusCode: status,
        cause: err,
        stackTrace: stackTrace,
      ),
      _ => UnknownException(
        message: message,
        statusCode: status,
        cause: err,
        stackTrace: stackTrace,
      ),
    };
  }

  /// A 400 carrying a field map is a validation error in everything but
  /// status code; without a map it is a generic bad request.
  AppException _asValidation(
    dynamic body,
    int status,
    String message,
    DioException err,
    StackTrace stackTrace,
  ) {
    final Map<String, List<String>> fields =
        _safely(() => _envelope.extractFieldErrors(body)) ??
        const <String, List<String>>{};

    if (fields.isEmpty && status == 400) {
      return UnknownException(
        message: message,
        statusCode: status,
        cause: err,
        stackTrace: stackTrace,
      );
    }

    return ValidationException(
      message: message,
      statusCode: status,
      fieldErrors: fields,
      serverMessage: _safely(() => _envelope.extractMessage(body)),
      cause: err,
      stackTrace: stackTrace,
    );
  }

  static Duration? _retryAfter(Response<dynamic>? response) {
    final String? header = response?.headers.value('retry-after');
    final int? seconds = header == null ? null : int.tryParse(header);
    return seconds == null ? null : Duration(seconds: seconds);
  }

  /// Envelope parsing runs against whatever the server actually sent, which
  /// on an error path is often an HTML proxy page rather than JSON. A failure
  /// to read it must not replace the real error with a cast exception.
  static T? _safely<T>(T? Function() body) {
    try {
      return body();
    } catch (_) {
      return null;
    }
  }
}
