import 'package:equatable/equatable.dart';

/// The single error vocabulary the whole app speaks.
///
/// Data sources throw these, repositories carry them inside `Result`, and
/// blocs turn them into an error state. Nothing below this layer leaks
/// upwards: a `DioException`, a `SocketException` or a failed JSON cast is
/// translated into one of the variants here before it crosses a repository
/// boundary, so a widget never has to know the app uses Dio at all.
///
/// This is deliberately *one* hierarchy rather than the classic mirrored
/// exception/failure pair. These types are already framework-free, so a
/// second parallel set of classes would add files to keep in sync without
/// buying any extra isolation.
sealed class AppException extends Equatable implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
    this.cause,
    this.stackTrace,
  });

  /// Technical detail, for logs and crash reports. Never rendered to a user.
  final String message;

  /// HTTP status when the failure came from a response, otherwise null.
  final int? statusCode;

  /// The original error, kept so crash reporting keeps its fidelity.
  final Object? cause;

  final StackTrace? stackTrace;

  /// Copy that is safe to put in front of a user.
  ///
  /// Every variant supplies its own, which is why no widget in this codebase
  /// ever needs to `switch` over error types just to build a message.
  String get userMessage;

  /// Whether offering a "Try again" affordance makes sense.
  ///
  /// False for the failures that will fail identically on a second attempt —
  /// a validation error or a 404 is not fixed by retrying.
  bool get isRetryable => false;

  /// Whether the session is gone and the app must return to login.
  bool get requiresReAuthentication => false;

  @override
  List<Object?> get props => <Object?>[runtimeType, message, statusCode];

  @override
  String toString() => '$runtimeType(status: $statusCode): $message';
}

// ---------------------------------------------------------------- Transport

/// The device could not reach the server at all — airplane mode, no DNS,
/// connection refused.
final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No network connection available.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'You appear to be offline. Check your connection and try again.';

  @override
  bool get isRetryable => true;
}

/// The request was sent but the server did not answer in time.
///
/// Named with the `Request` prefix so it does not collide with
/// `dart:async`'s `TimeoutException` at any import site.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException({
    super.message = 'The request timed out.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'This is taking longer than expected. Please try again.';

  @override
  bool get isRetryable => true;
}

/// The caller cancelled the request — usually a screen was disposed or a
/// newer search superseded this one. Almost always safe to swallow.
final class RequestCancelledException extends AppException {
  const RequestCancelledException({
    super.message = 'The request was cancelled.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage => 'The request was cancelled.';
}

// ----------------------------------------------------------------- Response

/// Any 5xx. The request was well formed; the server broke.
final class ServerException extends AppException {
  const ServerException({
    super.message = 'The server returned an error.',
    super.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'Something went wrong on our end. Please try again in a moment.';

  @override
  bool get isRetryable => true;
}

/// 401. The token is missing, expired beyond refresh, or revoked.
///
/// Reaching a bloc means the refresh flow in `AuthInterceptor` already tried
/// and failed, so the only remaining move is a return to login.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Authentication is required.',
    super.statusCode = 401,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Your session has expired. Please sign in again.';

  @override
  bool get requiresReAuthentication => true;
}

/// 403. The caller is authenticated but not allowed to do this — a role or
/// permission problem, not a token problem. Signing in again will not help.
final class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access to this resource is forbidden.',
    super.statusCode = 403,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'You do not have permission to perform this action.';
}

/// 404.
final class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage => 'We could not find what you were looking for.';
}

/// 409 — the write lost a race, or violates a uniqueness rule.
final class ConflictException extends AppException {
  const ConflictException({
    super.message = 'The request conflicts with the current state.',
    super.statusCode = 409,
    this.serverMessage,
    super.cause,
    super.stackTrace,
  });

  /// The server's own explanation, which for a conflict is usually the most
  /// useful thing to show ("This lead was already assigned").
  final String? serverMessage;

  @override
  String get userMessage =>
      serverMessage ?? 'That action conflicts with a recent change.';

  @override
  List<Object?> get props => <Object?>[...super.props, serverMessage];
}

/// 422 (or 400 with a field map). Carries the per-field errors so a form can
/// highlight the offending inputs instead of showing one flat message.
final class ValidationException extends AppException {
  const ValidationException({
    super.message = 'The submitted data was rejected.',
    super.statusCode = 422,
    this.fieldErrors = const <String, List<String>>{},
    this.serverMessage,
    super.cause,
    super.stackTrace,
  });

  /// Field name to the messages the server raised against it.
  final Map<String, List<String>> fieldErrors;

  final String? serverMessage;

  /// First message for [field], or null when that field is fine. Wire this
  /// straight into a `TextFormField.errorText`.
  String? errorFor(String field) => fieldErrors[field]?.firstOrNull;

  @override
  String get userMessage {
    if (serverMessage != null && serverMessage!.isNotEmpty) {
      return serverMessage!;
    }
    final String? first = fieldErrors.values
        .expand<String>((List<String> messages) => messages)
        .firstOrNull;
    return first ?? 'Please check the highlighted fields and try again.';
  }

  @override
  List<Object?> get props => <Object?>[
    ...super.props,
    fieldErrors,
    serverMessage,
  ];
}

/// 429. The server asked the client to slow down.
final class RateLimitException extends AppException {
  const RateLimitException({
    super.message = 'Too many requests.',
    super.statusCode = 429,
    this.retryAfter,
    super.cause,
    super.stackTrace,
  });

  /// How long the server asked us to wait, parsed from `Retry-After`.
  final Duration? retryAfter;

  @override
  String get userMessage => 'Too many requests. Please wait a moment.';

  @override
  bool get isRetryable => true;

  @override
  List<Object?> get props => <Object?>[...super.props, retryAfter];
}

// -------------------------------------------------------------------- Local

/// The response arrived but did not look like what the model expected.
///
/// This is a bug — either the contract changed or the parser is wrong — so it
/// is worth logging loudly rather than showing a friendly shrug and moving on.
final class ParseException extends AppException {
  const ParseException({
    super.message = 'The server response could not be parsed.',
    super.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'We received an unexpected response. Please try again.';
}

/// Reading or writing local storage failed.
final class CacheException extends AppException {
  const CacheException({
    super.message = 'A local storage operation failed.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Could not access local data.';
}

/// The catch-all. Anything landing here is unclassified and should be treated
/// as a gap in the mapping rather than a normal outcome.
final class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Something went wrong. Please try again.';

  @override
  bool get isRetryable => true;
}
