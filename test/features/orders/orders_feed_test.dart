import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/mappers/order_mapper.dart';
import 'package:jameia_mart/src/core/data/models/order_model.dart';
import 'package:jameia_mart/src/core/domain/entities/order_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/orders_feed.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/orders_page.dart';

import 'order_test_fixtures.dart';

void main() {
  OrderEntity order(String id, String status) =>
      OrderModel.fromJson(orderJson(id: id, status: status)).toEntity();

  OrdersPage page(List<OrderEntity> orders, {int at = 1, bool more = false}) =>
      OrdersPage(orders: orders, page: at, hasMore: more);

  test('the buckets are computed once, not per build', () {
    final feed = OrdersFeed.empty.replace(
      page(<OrderEntity>[
        order('o1', 'placed'),
        order('o2', 'delivered'),
        order('o3', 'cancelled'),
        order('o4', 'delivery_failed'),
      ]),
    );

    expect(feed.byGroup(OrderStatusGroup.inProgress), hasLength(1));
    expect(feed.byGroup(OrderStatusGroup.completed), hasLength(1));
    expect(feed.byGroup(OrderStatusGroup.cancelled), hasLength(2));
    expect(
      identical(feed.inProgress, feed.byGroup(OrderStatusGroup.inProgress)),
      isTrue,
    );
  });

  test('merge appends the next page and drops rows already loaded', () {
    final first = OrdersFeed.empty.replace(
      page(<OrderEntity>[order('o1', 'placed')], more: true),
    );

    final merged = first.merge(
      page(<OrderEntity>[order('o1', 'placed'), order('o2', 'placed')], at: 2),
    );

    expect(merged.orders.map((order) => order.id), <String>['o1', 'o2']);
    expect(merged.page, 2);
    expect(merged.hasMore, isFalse);
  });

  test('replace drops everything loaded before it', () {
    final feed = OrdersFeed.empty
        .replace(page(<OrderEntity>[order('o1', 'placed')], more: true))
        .merge(page(<OrderEntity>[order('o2', 'placed')], at: 2));

    final refreshed = feed.replace(page(<OrderEntity>[order('o9', 'placed')]));

    expect(refreshed.orders.map((order) => order.id), <String>['o9']);
    expect(refreshed.page, 1);
  });

  test('withOrder replaces the row in place and re-buckets it', () {
    final feed = OrdersFeed.empty.replace(
      page(<OrderEntity>[order('o1', 'placed'), order('o2', 'placed')]),
    );

    final updated = feed.withOrder(order('o1', 'cancelled'));

    expect(updated.orders.map((order) => order.id), <String>['o1', 'o2']);
    expect(updated.byGroup(OrderStatusGroup.cancelled).single.id, 'o1');
    expect(updated.byGroup(OrderStatusGroup.inProgress).single.id, 'o2');
  });

  test('an order the feed does not know goes on top', () {
    final feed = OrdersFeed.empty.replace(
      page(<OrderEntity>[order('o2', 'placed')]),
    );

    final updated = feed.withOrder(order('o1', 'placed'));

    expect(updated.orders.map((order) => order.id), <String>['o1', 'o2']);
  });
}
