/// Stable `statusMessage` codes the backend returns in every envelope.
///
/// Branch on THESE (plus the HTTP status), never on the localized
/// `error.message` — that text changes with `Accept-Language`.
///
/// Reference: https://docs.jm3eia.store/developers/errors.html
abstract final class ApiStatus {
  // 2xx
  static const String success = 'SUCCESS';
  static const String created = 'CREATED';
  static const String updated = 'UPDATED';
  static const String deleted = 'DELETED';
  static const String dataLoaded = 'DATA_LOADED';

  // 400 validation / business rules
  static const String validationError = 'VALIDATION_ERROR';
  static const String slugTaken = 'SLUG_TAKEN';
  static const String outOfStock = 'OUT_OF_STOCK';
  static const String cartEmpty = 'CART_EMPTY';

  // 401 authentication
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String invalidToken = 'INVALID_TOKEN';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String authenticationRequired = 'AUTHENTICATION_REQUIRED';
  static const String unauthenticated = 'UNAUTHENTICATED';

  // 403 authorization
  static const String forbidden = 'FORBIDDEN';
  static const String accessDenied = 'ACCESS_DENIED';

  // 404 / 409
  static const String resourceNotFound = 'RESOURCE_NOT_FOUND';
  static const String resourceExists = 'RESOURCE_EXISTS';

  // 429 rate limiting
  static const String rateLimited = 'RATE_LIMITED';
  static const String tooManyAttempts = 'TOO_MANY_ATTEMPTS';

  // 5xx
  static const String internalError = 'INTERNAL_ERROR';
  static const String serviceUnavailable = 'SERVICE_UNAVAILABLE';
}
