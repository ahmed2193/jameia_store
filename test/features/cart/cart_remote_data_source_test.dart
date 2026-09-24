import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/features/cart/data/datasources/cart_remote_data_source.dart';

import '../../core/network/network_test_fakes.dart';
import 'cart_test_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late CartRemoteDataSourceImpl dataSource;

  CartRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    return CartRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
    );
  }

  RequestOptions request() => adapter.requests.single;
  Map<String, dynamic> body() =>
      jsonDecode(jsonEncode(request().data)) as Map<String, dynamic>;

  test('getCart GETs /v1/cart and parses the cart', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));

    final cart = await dataSource.getCart();

    expect(request().method, 'GET');
    expect(request().path, '/v1/cart');
    expect(cart.cartToken, 'ct-1');
  });

  test('addItems POSTs the batch to /v1/cart/items', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));

    await dataSource.addItems(<Map<String, dynamic>>[
      <String, dynamic>{'productId': 'p1', 'quantity': 2},
      <String, dynamic>{'productId': 'p2', 'variantId': 'v1', 'quantity': 1},
    ]);

    expect(request().method, 'POST');
    expect(request().path, '/v1/cart/items');
    expect((body()['items'] as List<dynamic>), hasLength(2));
  });

  test(
    'setLineQuantity PATCHes the line key with an absolute quantity',
    () async {
      dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));

      await dataSource.setLineQuantity('l1', 4);

      expect(request().method, 'PATCH');
      expect(request().path, '/v1/cart/items/l1');
      expect(body()['quantity'], 4);
    },
  );

  test('removeLine DELETEs the line key', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));

    await dataSource.removeLine('l1');

    expect(request().method, 'DELETE');
    expect(request().path, '/v1/cart/items/l1');
  });

  test('clear DELETEs /v1/cart', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));

    await dataSource.clear();

    expect(request().method, 'DELETE');
    expect(request().path, '/v1/cart');
  });

  test('coupon, loyalty and express send their fields', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));
    await dataSource.applyCoupon('WELCOME');
    expect(body()['code'], 'WELCOME');

    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));
    await dataSource.applyLoyalty(120);
    expect(body()['points'], 120);

    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(cartJson())));
    await dataSource.setExpress(enabled: true);
    expect(body()['enabled'], isTrue);
    expect(request().path, '/v1/cart/express');
  });

  test('an OUT_OF_STOCK rejection surfaces as a typed exception', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(
          status: 400,
          statusMessage: 'OUT_OF_STOCK',
          errorMessage: 'Basmati rice is out of stock',
        ),
      ),
    );

    await expectLater(
      dataSource.addItems(<Map<String, dynamic>>[
        <String, dynamic>{'productId': 'p1', 'quantity': 2},
      ]),
      throwsA(
        isA<BadRequestException>()
            .having((error) => error.code, 'code', 'OUT_OF_STOCK')
            .having((error) => error.statusCode, 'statusCode', 400),
      ),
    );
  });

  test('a non-object payload throws ParsingException', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody('nope')));

    await expectLater(dataSource.getCart(), throwsA(isA<ParsingException>()));
  });
}
