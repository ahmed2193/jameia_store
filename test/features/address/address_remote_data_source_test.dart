// The address routes through the real DioConsumer on a scripted transport:
// method, path, body, the envelope unwrap and the error mapping.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/features/address/data/datasources/address_remote_data_source.dart';

import '../../core/network/network_test_fakes.dart';
import 'address_test_fakes.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  AddressRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    final dio = Dio()..httpClientAdapter = adapter;
    return AddressRemoteDataSourceImpl(DioConsumer(dio));
  }

  RequestOptions request() => adapter.requests.single;

  Map<String, dynamic> bodyOf(RequestOptions options) =>
      Map<String, dynamic>.from(options.data as Map);

  group('getAddresses', () {
    test('GETs /v1/account/addresses and parses every row', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) =>
              okBody([addressJson(n: 1, isDefault: true), addressJson(n: 2)]),
        ),
      );
      final rows = await dataSource.getAddresses();
      expect(request().method, 'GET');
      expect(request().path, EndPoints.accountAddresses);
      expect(rows.map((r) => r.id), [addressId(1), addressId(2)]);
      expect(rows.first.isDefault, isTrue);
    });

    test('an empty book is an empty list', () async {
      final dataSource = build(FakeHttpClientAdapter((_, _) => okBody([])));
      expect(await dataSource.getAddresses(), isEmpty);
    });

    test('a non-list payload throws ParsingException', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody({'data': []})),
      );
      await expectLater(
        dataSource.getAddresses(),
        throwsA(isA<ParsingException>()),
      );
    });

    test(
      'guest: 401 AUTHENTICATION_REQUIRED → UnauthorizedException',
      () async {
        final dataSource = build(
          FakeHttpClientAdapter(
            (_, _) => envelope(
              status: 401,
              statusMessage: 'AUTHENTICATION_REQUIRED',
              errorMessage: 'Sign in to continue',
            ),
          ),
        );
        await expectLater(
          dataSource.getAddresses(),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );
  });

  group('createAddress', () {
    test('POSTs the body and unwraps { address }', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({'address': addressJson(n: 7, label: 'Work')}),
        ),
      );
      final body = {'label': 'Work', 'lat': 29.3, 'lng': 48.0, 'city': 'X'};
      final saved = await dataSource.createAddress(body);
      expect(request().method, 'POST');
      expect(request().path, EndPoints.accountAddresses);
      expect(bodyOf(request()), body);
      expect(saved.id, addressId(7));
      expect(saved.label, 'Work');
    });

    test('a reply without `address` throws ParsingException', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody({'message': 'ok'})),
      );
      await expectLater(
        dataSource.createAddress(const {}),
        throwsA(isA<ParsingException>()),
      );
    });

    test(
      '400 VALIDATION_ERROR → BadRequestException with the code + details',
      () async {
        final dataSource = build(
          FakeHttpClientAdapter(
            (_, _) => envelope(
              status: 400,
              statusMessage: 'VALIDATION_ERROR',
              errorMessage: 'Validation failed',
              errorData: [
                {
                  'key': 'city',
                  'message': 'must NOT have fewer than 1 characters',
                },
              ],
            ),
          ),
        );
        await expectLater(
          dataSource.createAddress(const {}),
          throwsA(
            isA<BadRequestException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR')
                .having((e) => e.details, 'details', hasLength(1)),
          ),
        );
      },
    );
  });

  group('updateAddress', () {
    test('PATCHes /:addressId with the changed fields only', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({'address': addressJson(n: 3, isDefault: true)}),
        ),
      );
      final saved = await dataSource.updateAddress(addressId(3), {
        'isDefault': true,
      });
      expect(request().method, 'PATCH');
      expect(request().path, EndPoints.accountAddress(addressId(3)));
      expect(bodyOf(request()), {'isDefault': true});
      expect(saved.isDefault, isTrue);
    });

    test('an id that is not an ObjectId never reaches the network', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody({'address': addressJson()})),
      );
      for (final bad in ['..', '.', '../../auth/logout', 'abc']) {
        await expectLater(
          dataSource.updateAddress(bad, const {'floor': '1'}),
          throwsA(isA<ParsingException>()),
          reason: bad,
        );
        await expectLater(
          dataSource.deleteAddress(bad),
          throwsA(isA<ParsingException>()),
          reason: bad,
        );
      }
      expect(adapter.requests, isEmpty);
    });

    test('404 RESOURCE_NOT_FOUND → NotFoundException', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: 404,
            statusMessage: 'RESOURCE_NOT_FOUND',
            errorMessage: 'Not found',
          ),
        ),
      );
      await expectLater(
        dataSource.updateAddress(addressId(1), const {'floor': '1'}),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('deleteAddress', () {
    test('DELETEs /:addressId', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody({'message': 'Deleted'})),
      );
      await dataSource.deleteAddress(addressId(4));
      expect(request().method, 'DELETE');
      expect(request().path, EndPoints.accountAddress(addressId(4)));
    });
  });
}
