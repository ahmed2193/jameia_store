/// Typed exceptions THROWN by the data layer (datasources / [DioConsumer]).
///
/// Clean-arch convention (do not break):
///   * Datasources THROW these — they never return `Either`.
///   * `RepositoryImpl` try/catch wraps them into `Left(<Failure>)`.
///   * The domain layer (use cases, entities, cubits) NEVER imports this file.
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NoInternetConnectionException extends ServerException {
  const NoInternetConnectionException([String message = 'No internet connection'])
      : super(message, -7);
}

class UnauthorizedException extends ServerException {
  const UnauthorizedException([String message = 'Unauthorized']) : super(message, 401);
}

class BadRequestException extends ServerException {
  const BadRequestException([String message = 'Bad request']) : super(message, 400);
}

class NotFoundException extends ServerException {
  const NotFoundException([String message = 'Not found']) : super(message, 404);
}

class TimeoutException extends ServerException {
  const TimeoutException([String message = 'Request timed out']) : super(message, -2);
}

class CacheException extends ServerException {
  const CacheException([String message = 'Local cache error']) : super(message, -5);
}
