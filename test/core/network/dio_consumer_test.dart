import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/constants/app_env.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/api_headers.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';

import 'network_test_fakes.dart';

void main() {
  late Dio dio;

  DioConsumer consumerWith(FakeHttpClientAdapter adapter) {
    dio = Dio()..httpClientAdapter = adapter;
    return DioConsumer(dio);
  }

  test('applies the shared base options', () {
    consumerWith(FakeHttpClientAdapter((_, _) => okBody(null)));

    expect(dio.options.baseUrl, AppEnv.apiBaseUrl);
    expect(dio.options.headers[ApiHeaders.accept], ApiHeaders.jsonMediaType);
    expect(dio.options.contentType, ApiHeaders.jsonMediaType);
    expect(dio.options.responseType, ResponseType.json);
  });

  test('GET unwraps the envelope and returns results', () async {
    final adapter = FakeHttpClientAdapter(
      (_, _) => okBody({
        'data': [1, 2],
        'pagination': {'hasMore': false},
      }),
    );
    final consumer = consumerWith(adapter);

    final results = await consumer.get(
      '/v1/products',
      queryParameters: {'page': 1},
    );

    expect(results, {
      'data': [1, 2],
      'pagination': {'hasMore': false},
    });
    expect(adapter.requests.single.uri.path, '/v1/products');
    expect(adapter.requests.single.uri.queryParameters, {'page': '1'});
  });

  test('a non-envelope body passes through unchanged', () async {
    final consumer = consumerWith(
      FakeHttpClientAdapter(
        (_, _) => ResponseBody.fromString(
          '{"plain":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      ),
    );

    expect(await consumer.get('/other'), {'plain': true});
  });

  test('a 200 whose envelope says success:false throws by statusCode', () {
    final consumer = consumerWith(
      FakeHttpClientAdapter(
        (_, _) => ResponseBody.fromString(
          '{"success":false,"statusCode":400,"statusMessage":"CART_EMPTY",'
          '"results":null,"error":{"message":"Cart is empty","data":[]}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      ),
    );

    expect(
      () => consumer.post('/v1/orders', body: {'paymentMethod': 'cod'}),
      throwsA(
        isA<BadRequestException>()
            .having((e) => e.code, 'code', 'CART_EMPTY')
            .having((e) => e.message, 'message', 'Cart is empty'),
      ),
    );
  });

  group('HTTP status mapping', () {
    Future<void> expectStatus(
      int status,
      String code,
      Matcher matcher, {
      Map<String, List<String>> headers = const {},
    }) async {
      final consumer = consumerWith(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: status,
            statusMessage: code,
            errorMessage: 'msg-$status',
            headers: headers,
          ),
        ),
      );
      await expectLater(() => consumer.get('/x'), throwsA(matcher));
    }

    test(
      '400 → BadRequestException with code',
      () => expectStatus(
        400,
        'VALIDATION_ERROR',
        isA<BadRequestException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')
            .having((e) => e.statusCode, 'statusCode', 400),
      ),
    );

    test(
      '401 → UnauthorizedException',
      () => expectStatus(
        401,
        'TOKEN_EXPIRED',
        isA<UnauthorizedException>().having(
          (e) => e.code,
          'code',
          'TOKEN_EXPIRED',
        ),
      ),
    );

    test(
      '403 → ForbiddenException',
      () => expectStatus(403, 'FORBIDDEN', isA<ForbiddenException>()),
    );

    test(
      '404 → NotFoundException',
      () => expectStatus(
        404,
        'RESOURCE_NOT_FOUND',
        isA<NotFoundException>().having((e) => e.message, 'message', 'msg-404'),
      ),
    );

    test(
      '429 → RateLimitedException honouring Retry-After',
      () => expectStatus(
        429,
        'RATE_LIMITED',
        isA<RateLimitedException>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 7),
        ),
        headers: {
          ApiHeaders.retryAfter: ['7'],
        },
      ),
    );

    test(
      '500 → ServerException with status + code',
      () => expectStatus(
        500,
        'INTERNAL_ERROR',
        isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.code, 'code', 'INTERNAL_ERROR'),
      ),
    );
  });

  group('transport failures', () {
    test('timeouts → RequestTimeoutException', () {
      final consumer = consumerWith(
        FakeHttpClientAdapter(
          (options, _) => throw DioException.connectionTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: options,
          ),
        ),
      );
      expect(() => consumer.get('/x'), throwsA(isA<RequestTimeoutException>()));
    });

    test('connection errors → NoInternetConnectionException', () {
      final consumer = consumerWith(
        FakeHttpClientAdapter(
          (options, _) => throw DioException.connectionError(
            requestOptions: options,
            reason: 'refused',
          ),
        ),
      );
      expect(
        () => consumer.get('/x'),
        throwsA(isA<NoInternetConnectionException>()),
      );
    });
  });
}
