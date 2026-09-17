import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../core/network/network_test_fakes.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late AuthRemoteDataSourceImpl dataSource;

  AuthRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    final dio = Dio()..httpClientAdapter = adapter;
    return AuthRemoteDataSourceImpl(DioConsumer(dio));
  }

  Map<String, dynamic> sentBody() =>
      Map<String, dynamic>.from(adapter.requests.single.data as Map);

  test('sendOtp posts { phone } and parses message + echoed code', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody({'message': 'Code sent', 'code': 1234}),
      ),
    );

    final challenge = await dataSource.sendOtp('+96512345678');

    expect(adapter.requests.single.path, EndPoints.authSendOtp);
    expect(adapter.requests.single.method, 'POST');
    expect(sentBody(), {'phone': '+96512345678'});
    expect(challenge.message, 'Code sent');
    expect(challenge.code, '1234');
  });

  test(
    'verifyOtp posts { phone, code } and parses customer + tokens',
    () async {
      dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'customer': {
              '_id': 'abc',
              'phone': '+96512345678',
              'name': {'en': 'Ahmed', 'ar': 'أحمد'},
            },
            'accessToken': 'jwt',
            'refreshToken': 'opaque',
            'tokenType': 'Bearer',
            'expiresIn': 900,
          }),
        ),
      );

      final session = await dataSource.verifyOtp(
        phone: '+96512345678',
        code: '1234',
      );

      expect(adapter.requests.single.path, EndPoints.authVerifyOtp);
      expect(sentBody(), {'phone': '+96512345678', 'code': '1234'});
      expect(session.customer.id, 'abc');
      expect(session.customer.nameEn, 'Ahmed');
      expect(session.customer.nameAr, 'أحمد');
      expect(session.tokens.accessToken, 'jwt');
      expect(session.tokens.refreshToken, 'opaque');
    },
  );

  test('verifyOtp without a customer object throws ParsingException', () {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody({'accessToken': 'jwt', 'refreshToken': 'r'}),
      ),
    );

    expect(
      () => dataSource.verifyOtp(phone: '+96512345678', code: '1234'),
      throwsA(isA<ParsingException>()),
    );
  });

  test('a 400 envelope surfaces as BadRequestException with the code', () {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(
          status: 400,
          statusMessage: 'INVALID_CREDENTIALS',
          errorMessage: 'Wrong code',
        ),
      ),
    );

    expect(
      () => dataSource.verifyOtp(phone: '+96512345678', code: '0000'),
      throwsA(
        isA<BadRequestException>()
            .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')
            .having((e) => e.message, 'message', 'Wrong code'),
      ),
    );
  });

  test('me GETs /v1/account/me and parses the customer', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) =>
            okBody({'_id': 'abc', 'phone': '+96512345678', 'name': 'Ahmed'}),
      ),
    );

    final me = await dataSource.me();

    expect(adapter.requests.single.path, EndPoints.accountMe);
    expect(adapter.requests.single.method, 'GET');
    expect(me.id, 'abc');
    expect(me.nameEn, 'Ahmed');
    expect(me.nameAr, 'Ahmed');
  });

  test('logout posts to the logout route', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));

    await dataSource.logout();

    expect(adapter.requests.single.path, EndPoints.authLogout);
  });
}
