import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/network/api_headers.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/interceptors/app_headers_interceptor.dart';

import 'network_test_fakes.dart';

void main() {
  late InMemorySessionStore session;
  late FakeLocaleProvider locale;
  late FakeHttpClientAdapter adapter;
  late DioConsumer consumer;

  setUp(() {
    session = InMemorySessionStore();
    locale = FakeLocaleProvider('ar');
    adapter = FakeHttpClientAdapter((_, _) => okBody(null));
    final dio = Dio()..httpClientAdapter = adapter;
    consumer = DioConsumer(
      dio,
      interceptors: [AppHeadersInterceptor(locale: locale, session: session)],
    );
  });

  Map<String, dynamic> sent() => adapter.requests.single.headers;

  test('always sends Accept-Language from the LocaleProvider', () async {
    await consumer.get('/v1/home');
    expect(sent()[ApiHeaders.acceptLanguage], 'ar');
  });

  test(
    'guest: sends X-Cart-Token (when known) + a generated X-Assistant-Guest',
    () async {
      session.cartToken = 'cart-123';
      await consumer.get('/v1/cart');

      expect(sent()[ApiHeaders.cartToken], 'cart-123');
      expect(sent()[ApiHeaders.assistantGuest], hasLength(32));
      expect(sent()[ApiHeaders.authorization], isNull);
    },
  );

  test('guest without a cart token omits X-Cart-Token', () async {
    await consumer.get('/v1/cart');
    expect(sent().containsKey(ApiHeaders.cartToken), isFalse);
    expect(sent()[ApiHeaders.assistantGuest], isNotNull);
  });

  test('signed in: guest identity headers are dropped', () async {
    session
      ..accessToken = 'jwt'
      ..cartToken = 'cart-123'
      ..assistantGuestKey = 'b' * 32;
    await consumer.get('/v1/cart');

    expect(sent().containsKey(ApiHeaders.cartToken), isFalse);
    expect(sent().containsKey(ApiHeaders.assistantGuest), isFalse);
  });

  test('a caller-provided header wins', () async {
    await consumer.get('/v1/home', headers: {ApiHeaders.acceptLanguage: 'en'});
    expect(sent()[ApiHeaders.acceptLanguage], 'en');
  });
}
