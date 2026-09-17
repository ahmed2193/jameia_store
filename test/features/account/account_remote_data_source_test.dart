import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/features/account/data/datasources/account_remote_data_source.dart';

import '../../core/network/network_test_fakes.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  AccountRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    final dio = Dio()..httpClientAdapter = adapter;
    return AccountRemoteDataSourceImpl(DioConsumer(dio));
  }

  test('me GETs /v1/account/me and parses the customer', () async {
    final dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody({
          '_id': 'abc',
          'phone': '+96512345678',
          'name': 'Ahmed',
          'wallet': 500,
        }),
      ),
    );

    final me = await dataSource.me();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, EndPoints.accountMe);
    expect(me.id, 'abc');
    expect(me.wallet, 500);
  });

  test(
    'updateProfile PATCHes only the given fields and parses the reply',
    () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            '_id': 'abc',
            'phone': '+96512345678',
            'name': 'Ahmed Ali',
            'email': null,
          }),
        ),
      );

      final updated = await dataSource.updateProfile({
        'name': 'Ahmed Ali',
        'email': null,
      });

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, EndPoints.accountProfile);
      expect(Map<String, dynamic>.from(request.data as Map), {
        'name': 'Ahmed Ali',
        'email': null,
      });
      expect(updated.nameEn, 'Ahmed Ali');
      expect(updated.email, '');
    },
  );

  test('a non-object payload throws ParsingException', () {
    final dataSource = build(FakeHttpClientAdapter((_, _) => okBody([1, 2])));

    expect(dataSource.me, throwsA(isA<ParsingException>()));
  });

  test('401 surfaces as UnauthorizedException (guest)', () {
    final dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(
          status: 401,
          statusMessage: 'AUTHENTICATION_REQUIRED',
          errorMessage: 'Sign in to continue',
        ),
      ),
    );

    expect(
      dataSource.me,
      throwsA(
        isA<UnauthorizedException>().having(
          (e) => e.code,
          'code',
          'AUTHENTICATION_REQUIRED',
        ),
      ),
    );
  });
}
