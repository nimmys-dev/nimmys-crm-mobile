/// Keys used in Dio's `RequestOptions.extra` bag.
///
/// `extra` is an untyped map shared by every interceptor, so the names are
/// collected here rather than written as literals at each site — a typo in a
/// string like `'requiresAuth'` fails silently and, for the auth flag,
/// silently means "send this request unauthenticated".
abstract final class RequestKeys {
  /// False for public endpoints: skip token attachment and skip the refresh
  /// dance on a 401.
  static const String requiresAuth = 'nimmys.requires_auth';

  /// Set by the auth interceptor after it replays a request post-refresh, so
  /// a second 401 is not retried forever.
  static const String didRetryAfterRefresh = 'nimmys.did_retry_after_refresh';

  /// Explicit per-request retry override; absent means "decide by method".
  static const String allowRetry = 'nimmys.allow_retry';

  /// Attempts the retry interceptor has already spent on this request.
  static const String retryCount = 'nimmys.retry_count';

  /// Status codes to accept as success beyond the usual 2xx.
  static const String expectedStatusCodes = 'nimmys.expected_status_codes';

  /// Monotonic id assigned by the logging interceptor so a request and its
  /// response can be matched in a log full of concurrent traffic.
  static const String requestId = 'nimmys.request_id';
}
