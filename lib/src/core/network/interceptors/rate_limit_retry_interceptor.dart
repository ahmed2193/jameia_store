import 'package:dio/dio.dart';

import '../api_exception_mapper.dart';

/// Retries `429 Too Many Requests` with exponential backoff, honouring a
/// `Retry-After` header when the server sends one (docs: "Retry 429 responses
/// with exponential backoff"). Gives up after [maxRetries] and lets the error
/// reach `ApiExceptionMapper` as a `RateLimitedException`.
class RateLimitRetryInterceptor extends Interceptor {
  RateLimitRetryInterceptor({
    required this._dio,
    this.maxRetries = defaultMaxRetries,
    this._wait = _sleep,
  });

  static const int defaultMaxRetries = 3;

  /// Backoff schedule: 1s, 2s, 4s (capped at [maxDelay]).
  static const Duration baseDelay = Duration(seconds: 1);
  static const Duration maxDelay = Duration(seconds: 8);

  /// `1s << 3 = 8s` already reaches the cap.
  static const int _maxBackoffShift = 3;
  static const int _tooManyRequests = 429;
  static const String _attemptKey = 'rateLimit.attempt';

  final Dio _dio;
  final int maxRetries;
  final Future<void> Function(Duration delay) _wait;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = options.extra[_attemptKey] as int? ?? 0;
    if (err.response?.statusCode != _tooManyRequests || attempt >= maxRetries) {
      return handler.next(err);
    }

    final delay =
        ApiExceptionMapper.retryAfterOf(err.response?.headers) ??
        backoffFor(attempt);
    await _wait(delay);
    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.reject(retryError);
    }
  }

  /// `baseDelay * 2^attempt`, capped at [maxDelay]. The exponent is clamped
  /// first — `1 << attempt` overflows for large attempts.
  static Duration backoffFor(int attempt) {
    if (attempt >= _maxBackoffShift) return maxDelay;
    final delay = baseDelay * (1 << attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  static Future<void> _sleep(Duration delay) => Future<void>.delayed(delay);
}
