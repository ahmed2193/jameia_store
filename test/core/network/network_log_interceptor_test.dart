import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/interceptors/network_log_interceptor.dart';

import 'network_test_fakes.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late List<String> blocks;

  DioConsumer build(
    FakeHttpClientAdapter transport, {
    bool revealSecrets = false,
    int maxBodyChars = NetworkLogInterceptor.defaultMaxBodyChars,
  }) {
    adapter = transport;
    blocks = [];
    final dio = Dio()..httpClientAdapter = adapter;
    return DioConsumer(
      dio,
      interceptors: [
        NetworkLogInterceptor(
          revealSecrets: revealSecrets,
          maxBodyChars: maxBodyChars,
          sink: blocks.add,
        ),
      ],
    );
  }

  test(
    'logs the request (masked headers + pretty body) and the response',
    () async {
      final consumer = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({'accessToken': 'eyJhbGciOiJIUzI1NiJ9.secret.9ypg'}),
        ),
      );

      await consumer.post(
        '/v1/auth/verify-otp',
        body: {'phone': '+96512345678', 'code': '1234'},
        headers: {'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.abc.9ypg'},
      );

      expect(blocks, hasLength(2));
      final request = blocks.first;
      expect(request, startsWith('--> #1 POST /v1/auth/verify-otp'));
      expect(request, contains('Authorization: Bearer eyJh…9ypg'));
      expect(request, isNot(contains('.abc.')));
      expect(request, contains('"phone": "+96512345678"'));
      expect(request, contains('"code": "1234"'));

      final response = blocks.last;
      expect(response, startsWith('<-- #1 200 POST /v1/auth/verify-otp ('));
      expect(response, contains('ms) SUCCESS'));
      expect(response, contains('"accessToken": "eyJh…9ypg"'));
      expect(response, isNot(contains('.secret.')));
    },
  );

  test('revealSecrets prints token values in full', () async {
    final consumer = build(
      FakeHttpClientAdapter(
        (_, _) => okBody({'refreshToken': 'ref_0123456789abcdef'}),
      ),
      revealSecrets: true,
    );

    await consumer.get(
      '/v1/x',
      headers: {'Authorization': 'Bearer full-token-value'},
    );

    expect(blocks.first, contains('Authorization: Bearer full-token-value'));
    expect(blocks.last, contains('"refreshToken": "ref_0123456789abcdef"'));
  });

  test('logs an error block with the envelope code for a 4xx', () async {
    final consumer = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(
          status: 401,
          statusMessage: 'TOKEN_EXPIRED',
          errorMessage: 'expired',
        ),
      ),
    );

    await expectLater(consumer.get('/v1/account/me'), throwsA(anything));

    expect(blocks, hasLength(2));
    expect(blocks.last, startsWith('xx  #1 401 GET /v1/account/me ('));
    expect(blocks.last, contains('TOKEN_EXPIRED'));
    expect(blocks.last, contains('"message": "expired"'));
  });

  test('logs the Dio error type when there is no response', () async {
    final consumer = build(
      FakeHttpClientAdapter(
        (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'refused',
        ),
      ),
    );

    await expectLater(consumer.get('/v1/home'), throwsA(anything));

    expect(blocks.last, startsWith('xx  #1 connectionError GET /v1/home'));
    expect(blocks.last, contains('type: connectionError'));
  });

  test('truncates long bodies and wraps long lines', () async {
    final long = 'x' * 2000;
    final consumer = build(
      FakeHttpClientAdapter((_, _) => okBody({'blob': long})),
      maxBodyChars: 100,
    );

    await consumer.get('/v1/x');

    final response = blocks.last;
    expect(response, contains('… [truncated]'));
    for (final line in response.split('\n')) {
      expect(
        line.length,
        lessThanOrEqualTo(NetworkLogInterceptor.maxLineChars),
      );
    }
  });

  test('numbers requests in sequence and summarises stream bodies', () async {
    final consumer = build(FakeHttpClientAdapter((_, _) => okBody(null)));

    await consumer.get('/v1/a');
    await consumer.get('/v1/b');

    expect(blocks[0], startsWith('--> #1 GET /v1/a'));
    expect(blocks[2], startsWith('--> #2 GET /v1/b'));
    expect(blocks[0], isNot(contains('body:'))); // GET: no request body
    expect(blocks[1], contains('"results": null'));

    final streamed = <String>[];
    final dio = Dio()
      ..httpClientAdapter = FakeHttpClientAdapter(
        (_, _) => ResponseBody.fromString('data: hi\n\n', 200),
      )
      ..interceptors.add(NetworkLogInterceptor(sink: streamed.add));
    await dio.get<ResponseBody>(
      '/v1/notifications/sse',
      options: Options(responseType: ResponseType.stream),
    );
    expect(streamed.last, contains('body: <stream>'));
  });

  test(
    'secrets are masked wherever they travel: query, guest header, lists',
    () async {
      final consumer = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'pushTokens': [
              'fcm_token_0123456789abcdef',
              'fcm_token_fedcba9876543210',
            ],
          }),
        ),
      );

      await consumer.get(
        '/v1/x',
        queryParameters: {'resetToken': 'reset_0123456789abcdef', 'page': 2},
        headers: {'X-Assistant-Guest': '0123456789abcdef0123456789abcdef'},
      );

      final request = blocks.first;
      final urlLine = request
          .split('\n')
          .firstWhere((line) => line.contains('url:'));
      expect(
        urlLine,
        isNot(contains('?')),
        reason: 'query never rides the url line',
      );
      expect(request, isNot(contains('reset_0123456789abcdef')));
      expect(request, contains('rese…cdef'));
      expect(request, contains('page: 2'));
      expect(request, contains('X-Assistant-Guest: 0123…cdef'));
      expect(blocks.last, isNot(contains('fcm_token_0123456789abcdef')));
      expect(blocks.last, contains('fcm_…cdef'));
    },
  );

  test('a response above the size budget is summarised, not encoded', () async {
    final consumer = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(
          status: 200,
          statusMessage: 'DATA_LOADED',
          results: {'big': true},
          headers: {
            Headers.contentLengthHeader: [
              '${NetworkLogInterceptor.maxTraceableBytes + 1}',
            ],
          },
        ),
      ),
    );

    await consumer.get('/v1/home');

    expect(blocks.last, contains('too large to trace'));
    expect(blocks.last, isNot(contains('"big"')));
  });

  test('a failing sink never breaks the request', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeHttpClientAdapter((_, _) => okBody({'ok': 1}));
    final consumer = DioConsumer(
      dio,
      interceptors: [
        NetworkLogInterceptor(sink: (_) => throw StateError('console gone')),
      ],
    );

    expect(await consumer.get('/v1/x'), {'ok': 1});
  });

  test('mask keeps 4 + 4 chars and hides short values entirely', () {
    expect(NetworkLogInterceptor.mask('abcdefghijklmnopqrst'), 'abcd…qrst');
    // 4 + 4 of a short value would give most of it away: hide it entirely.
    expect(NetworkLogInterceptor.mask('abcdefghijkl'), '***');
    expect(NetworkLogInterceptor.mask('short'), '***');
    expect(NetworkLogInterceptor.mask(''), '');
    expect(jsonEncode({'a': 1}), '{"a":1}'); // sanity: encoder available
  });
}
