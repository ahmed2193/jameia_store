import 'package:dio/dio.dart';

import '../error/exceptions.dart';
import 'api_envelope.dart';
import 'api_headers.dart';

/// Translates transport failures and error envelopes into the typed
/// `AppException` hierarchy — the ONE place that knows jm3eia HTTP semantics.
///
/// Reference: https://docs.jm3eia.store/developers/errors.html
abstract final class ApiExceptionMapper {
  static const String _fallbackMessage = 'Request failed';
  static const String _legacyMessageKey = 'message';

  static const int _badRequest = 400;
  static const int _unauthorized = 401;
  static const int _forbidden = 403;
  static const int _notFound = 404;
  static const int _tooManyRequests = 429;

  static AppException fromDio(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const RequestTimeoutException();
      case DioExceptionType.connectionError:
        return const NoInternetConnectionException();
      case DioExceptionType.badCertificate:
        return const NetworkException('Untrusted server certificate');
      case DioExceptionType.cancel:
        return const RequestCancelledException();
      case DioExceptionType.badResponse:
        return fromResponse(exception.response);
      case DioExceptionType.unknown:
        final cause = exception.error;
        // Interceptors surface already-typed errors (e.g. a refresh that hit
        // the network) by wrapping them in an `unknown` DioException.
        if (cause is AppException) return cause;
        if (cause is FormatException) return ParsingException(cause.message);
        return ServerException(exception.message ?? 'Unexpected network error');
    }
  }

  /// Maps a non-2xx [response]; reads the envelope when present.
  static AppException fromResponse(Response<dynamic>? response) {
    final envelope = ApiEnvelope.tryParse(response?.data);
    final message =
        envelope?.displayMessage ??
        _legacyMessage(response?.data) ??
        _fallbackMessage;
    return fromStatus(
      response?.statusCode,
      message: message,
      code: envelope?.statusMessage,
      details: envelope?.error?.details ?? const [],
      retryAfter: retryAfterOf(response?.headers),
    );
  }

  /// Maps a 2xx body whose envelope still says `success: false`.
  static AppException fromEnvelope(ApiEnvelope envelope) => fromStatus(
    envelope.statusCode,
    message: envelope.displayMessage,
    code: envelope.statusMessage,
    details: envelope.error?.details ?? const [],
  );

  static AppException fromStatus(
    int? status, {
    required String message,
    String? code,
    List<Object?> details = const [],
    Duration? retryAfter,
  }) {
    return switch (status) {
      _badRequest => BadRequestException(message, code: code, details: details),
      _unauthorized => UnauthorizedException(message, code: code),
      _forbidden => ForbiddenException(message, code: code),
      _notFound => NotFoundException(message, code: code),
      _tooManyRequests => RateLimitedException(
        message,
        code: code,
        retryAfter: retryAfter,
      ),
      _ => ServerException(message, statusCode: status, code: code),
    };
  }

  /// `Retry-After` in seconds, when the server sent one.
  static Duration? retryAfterOf(Headers? headers) {
    final raw = headers?.value(ApiHeaders.retryAfter);
    final seconds = raw == null ? null : int.tryParse(raw.trim());
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  static String? _legacyMessage(Object? body) {
    if (body is Map && body[_legacyMessageKey] is String) {
      return body[_legacyMessageKey] as String;
    }
    return null;
  }
}
