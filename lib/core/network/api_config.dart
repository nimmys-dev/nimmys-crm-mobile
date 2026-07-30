/// Environment-specific networking settings.
///
/// A value rather than a bag of statics so tests and flavors can inject their
/// own base URL without touching global state — `ApiConfig.staging` and a
/// mock server config are both just instances.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.retryBackoff = const Duration(milliseconds: 400),
    this.enableLogging = false,
  });

  /// Local development against a machine on the same network.
  ///
  /// `10.0.2.2` is the host loopback as seen from the Android emulator; an
  /// iOS simulator shares the host's own `localhost`.
  static const ApiConfig development = ApiConfig(
    baseUrl: 'http://10.0.2.2:8000/api/v1',
    enableLogging: true,
  );

  static const ApiConfig staging = ApiConfig(
    baseUrl: 'https://staging.api.nimmyscrm.com/v1',
    enableLogging: true,
  );

  static const ApiConfig production = ApiConfig(
    baseUrl: 'https://api.nimmyscrm.com/v1',
  );

  final String baseUrl;

  /// Time allowed to establish the TCP/TLS connection. Kept well below the
  /// read timeouts because a connection that has not opened in 15s is not
  /// going to open.
  final Duration connectTimeout;

  final Duration sendTimeout;
  final Duration receiveTimeout;

  /// How many times a *retryable* request is re-sent before giving up.
  /// See `RetryInterceptor` for what counts as retryable.
  final int maxRetries;

  /// Base delay for exponential backoff between retries.
  final Duration retryBackoff;

  /// Whether request/response bodies are logged. Must stay false in release:
  /// bodies routinely contain tokens and customer data.
  final bool enableLogging;

  ApiConfig copyWith({String? baseUrl, bool? enableLogging, int? maxRetries}) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryBackoff: retryBackoff,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }
}

/// Every path the app calls, in one place.
///
/// Centralising them means a backend rename is a single-file change, and it
/// keeps feature code free of string literals that are easy to typo and
/// impossible to grep reliably.
abstract final class Endpoints {
  // --------------------------------------------------------------- Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String currentUser = '/auth/me';

  // -------------------------------------------------------------- Leads
  static const String leads = '/leads';

  static String leadById(String id) => '/leads/$id';

  static String leadFollowUps(String id) => '/leads/$id/follow-ups';

  // ------------------------------------------------------------- Duties
  static const String duties = '/duties';

  static String dutyById(String id) => '/duties/$id';

  // -------------------------------------------------------------- Staff
  static const String staff = '/staff';

  // ---------------------------------------------------------- Dashboard
  static const String dashboardSummary = '/dashboard/summary';
}
