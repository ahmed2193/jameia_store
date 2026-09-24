import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/features/orders/data/datasources/orders_remote_data_source.dart';

import '../../core/network/network_test_fakes.dart';
import 'order_test_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late OrdersRemoteDataSourceImpl dataSource;

  OrdersRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    return OrdersRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
    );
  }

  RequestOptions request() => adapter.requests.single;
  Map<String, dynamic> body() =>
      jsonDecode(jsonEncode(request().data)) as Map<String, dynamic>;

  test('getOrders sends page + limit and parses the pagination', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody(ordersPageJson(page: 2, hasMore: true, total: 30)),
      ),
    );

    final page = await dataSource.getOrders(page: 2, limit: 20);

    expect(request().method, 'GET');
    expect(request().path, '/v1/orders');
    expect(request().queryParameters, <String, dynamic>{
      'page': 2,
      'limit': 20,
    });
    expect(page.page, 2);
    expect(page.hasMore, isTrue);
    expect(page.total, 30);
    expect(page.items, hasLength(1));
  });

  test('a malformed row is skipped, the page survives', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody(
          ordersPageJson(
            orders: <Map<String, dynamic>>[
              orderJson(),
              <String, dynamic>{'status': 'placed'}, // no id
            ],
          ),
        ),
      ),
    );

    final page = await dataSource.getOrders(page: 1, limit: 20);

    expect(page.items, hasLength(1));
  });

  test('getOrder GETs the order by id', () async {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody(orderJson())));

    final order = await dataSource.getOrder('o1');

    expect(request().method, 'GET');
    expect(request().path, '/v1/orders/o1');
    expect(order.orderNumber, 'JM-1001');
  });

  test('cancelOrder POSTs the reason and note', () async {
    dataSource = build(
      FakeHttpClientAdapter((_, _) => okBody(orderJson(status: 'cancelled'))),
    );

    final order = await dataSource.cancelOrder('o1', <String, dynamic>{
      'reason': 'changed_mind',
      'note': 'sorry',
    });

    expect(request().method, 'POST');
    expect(request().path, '/v1/orders/o1/cancel');
    expect(body()['reason'], 'changed_mind');
    expect(order.status, 'cancelled');
  });

  test('a cancel the backend refuses surfaces as a typed exception', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(
          status: 400,
          statusMessage: 'ORDER_NOT_CANCELLABLE',
          errorMessage: 'This order can no longer be cancelled',
        ),
      ),
    );

    await expectLater(
      dataSource.cancelOrder('o1', <String, dynamic>{'reason': 'too_slow'}),
      throwsA(
        isA<BadRequestException>().having(
          (error) => error.code,
          'code',
          'ORDER_NOT_CANCELLABLE',
        ),
      ),
    );
  });

  test('submitReview POSTs to /v1/reviews', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody(const <String, dynamic>{'message': 'thanks'}),
      ),
    );

    await dataSource.submitReview(<String, dynamic>{
      'productId': 'p1',
      'orderId': 'o1',
      'rating': 5,
    });

    expect(request().method, 'POST');
    expect(request().path, '/v1/reviews');
    expect(body()['rating'], 5);
  });

  test('a 401 on a customer route surfaces as unauthorized', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(status: 401, statusMessage: 'UNAUTHORIZED'),
      ),
    );

    await expectLater(
      dataSource.getOrders(page: 1, limit: 20),
      throwsA(isA<UnauthorizedException>()),
    );
  });
}
