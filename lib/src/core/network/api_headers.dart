/// Header names + media types the jm3eia API contract uses. Every interceptor
/// and datasource references these — never a raw header string.
///
/// Reference: https://docs.jm3eia.store/developers/conventions.html
abstract final class ApiHeaders {
  static const String authorization = 'Authorization';
  static const String acceptLanguage = 'Accept-Language';
  static const String accept = 'Accept';
  static const String contentType = 'Content-Type';
  static const String retryAfter = 'Retry-After';

  /// Guest cart identity (`results.cartToken` from `/v1/init` or a cart call).
  /// Sent ONLY while signed out — signed-in customers use the Bearer token.
  static const String cartToken = 'X-Cart-Token';

  /// Guest assistant identity: a 32-char hex key generated on device and
  /// persisted. Merged into the customer on login, then dropped.
  static const String assistantGuest = 'X-Assistant-Guest';

  static const String bearerPrefix = 'Bearer ';
  static const String jsonMediaType = 'application/json';
  static const String eventStreamMediaType = 'text/event-stream';
}
