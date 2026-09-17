import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/api_headers.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/interceptors/rate_limit_retry_interceptor.dart';

import 'network_test_fakes.dart';

void main() {
  late List<Duration> waits;
  late FakeHttpClientAdapter adapter;

  DioConsumer build(
    FakeHttpClientAdapter transport, {
    int maxRetries = RateLimitRetryInterceptor.defaultMaxRetries,
  }) {
    adapter = transport;
    final dio = Dio()..httpClientAdapter = adapter;
    return DioConsumer(
      dio,
      interceptors: [
        RateLimitRetryInterceptor(
          dio: dio,
          maxRetries: maxRetries,
          wait: (delay) async => waits.add(delay),
        ),
      ],
    );
  }

  ResponseBody limited({Map<String, List<String>> headers = const {}}) =>
      envelope(
        status: 429,
        statusMessage: 'RATE_LIMITED',
        errorMessage: 'slow down',
        headers: headers,
      );

  setUp(() => waits = []);

  test('backoff doubles: 1s, 2s, 4s and caps at maxDelay', () {
    expect(RateLimitRetryInterceptor.backoffFor(0), const Duration(seconds: 1));
    expect(RateLimitRetryInterceptor.backoffFor(1), const Duration(seconds: 2));
    expect(RateLimitRetryInterceptor.backoffFor(2), const Duration(seconds: 4));
    expect(
      RateLimitRetryInterceptor.backoffFor(5),
      RateLimitRetryInterceptor.maxDelay,
    );
  });

  test('429 then 200 → resolves after one backoff wait', () async {
    final consumer = build(
      FakeHttpClientAdapter(
        (_, call) => call == 0 ? limited() : okBody({'ok': 1}),
      ),
    );

    expect(await consumer.get('/v1/assistant/conversations'), {'ok': 1});
    expect(adapter.requests, hasLength(2));
    expect(waits, [const Duration(seconds: 1)]);
  });

  test('honours Retry-After over the computed backoff', () async {
    final consumer = build(
      FakeHttpClientAdapter(
        (_, call) => call == 0
            ? limited(
                headers: {
                  ApiHeaders.retryAfter: ['5'],
                },
              )
            : okBody(null),
      ),
    );

    await consumer.get('/x');
    expect(waits, [const Duration(seconds: 5)]);
  });

  test('gives up after maxRetries and surfaces RateLimitedException', () async {
    final consumer = build(
      FakeHttpClientAdapter((_, _) => limited()),
      maxRetries: 2,
    );

    await expectLater(
      () => consumer.get('/x'),
      throwsA(
        isA<RateLimitedException>().having(
          (e) => e.code,
          'code',
          'RATE_LIMITED',
        ),
      ),
    );
    expect(adapter.requests, hasLength(3)); // original + 2 retries
    expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]);
  });

  test('non-429 errors are not retried', () async {
    final consumer = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(status: 500, statusMessage: 'INTERNAL_ERROR'),
      ),
    );

    await expectLater(
      () => consumer.get('/x'),
      throwsA(isA<ServerException>()),
    );
    expect(adapter.requests, hasLength(1));
    expect(waits, isEmpty);
  });
}
