/// Typed exceptions THROWN by the data layer (datasources / `DioConsumer`).
///
/// Clean-arch convention (do not break):
///   * Datasources THROW these — they never return `Either`.
///   * Repository implementations run every call through
///     `BaseRepositoryMixin.execute`, which maps them to a `Failure`.
///   * The domain + presentation layers NEVER import this file.
library;

/// Root of the exception hierarchy. Every data-layer failure is one of these.
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The server answered with an error: a non-2xx status, or a 2xx whose
/// envelope says `success: false`.
class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode, this.code});

  final int? statusCode;

  /// Stable backend `statusMessage` (see `ApiStatus`, e.g. `OUT_OF_STOCK`).
  /// Branch on THIS — [message] is localized and changes per language.
  final String? code;

  @override
  String toString() => 'ServerException($statusCode $code): $message';
}

/// 400 — validation / business-rule failure. [details] is the raw
/// `error.data` list (field-level messages) for form UIs.
class BadRequestException extends ServerException {
  const BadRequestException(
    super.message, {
    super.code,
    this.details = const [],
  }) : super(statusCode: 400);

  final List<Object?> details;
}

/// 401 — missing / invalid / expired credentials.
class UnauthorizedException extends ServerException {
  const UnauthorizedException(super.message, {super.code})
    : super(statusCode: 401);
}

/// 403 — authenticated but not allowed.
class ForbiddenException extends ServerException {
  const ForbiddenException(super.message, {super.code})
    : super(statusCode: 403);
}

/// 404 — resource not found.
class NotFoundException extends ServerException {
  const NotFoundException(super.message, {super.code}) : super(statusCode: 404);
}

/// 429 — rate limited (`RATE_LIMITED` / `TOO_MANY_ATTEMPTS`); [retryAfter] is
/// the server's `Retry-After` hint when sent.
class RateLimitedException extends ServerException {
  const RateLimitedException(super.message, {super.code, this.retryAfter})
    : super(statusCode: 429);

  final Duration? retryAfter;
}

/// The request never reached the server (no connectivity / timeout).
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

class NoInternetConnectionException extends NetworkException {
  const NoInternetConnectionException([
    super.message = 'No internet connection',
  ]);
}

/// Named `Request…` so it never clashes with `dart:async`'s `TimeoutException`.
class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException([super.message = 'Request timed out']);
}

/// The caller cancelled the request (Dio `CancelToken`).
class RequestCancelledException extends NetworkException {
  const RequestCancelledException([super.message = 'Request cancelled']);
}

/// Local persistence / in-memory catalogue read or write failed.
class CacheException extends AppException {
  const CacheException([super.message = 'Local cache error']);
}

/// A payload could not be decoded into the expected model.
class ParsingException extends AppException {
  const ParsingException([super.message = 'Could not parse data']);
}
