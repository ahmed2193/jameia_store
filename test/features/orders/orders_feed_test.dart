import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/orders/domain/entities/orders_feed.dart';
import 'package:hero_mart/src/features/orders/domain/entities/orders_page.dart';

import 'order_test_fixtures.dart';

void main() {
  OrderEntity order(String id, String status) =>
      OrderModel.fromJson(orderJson(id: id, status: status)).toEntity();

  OrdersPage page(List<OrderEntity> orders, {int at = 1, bool more = false}) =>
      OrdersPage(orders: orders, page: at, hasMore: more);

  test('every status lives in the one list, in the order sent', () {
    final feed = OrdersFeed.empty.replace(
      page(<OrderEntity>[
        order('o1', 'placed'),
        order('o2', 'delivered'),
        order('o3', 'cancelled'),
        order('o4', 'delivery_failed'),
      ]),
    );

    // Nothing is filtered out and nothing is re-ordered by status: the list
    // shows running, done and cancelled orders together.
    expect(feed.orders.map((order) => order.id), <String>[
      'o1',
      'o2',
      'o3',
      'o4',
    ]);
    expect(feed.orders.map((order) => order.group), <OrderStatusGroup>[
      OrderStatusGroup.inProgress,
      OrderStatusGroup.completed,
      OrderStatusGroup.cancelled,
      OrderStatusGroup.cancelled,
    ]);
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

  test('withOrder replaces the row in place, keeping its position', () {
    final feed = OrdersFeed.empty.replace(
      page(<OrderEntity>[order('o1', 'placed'), order('o2', 'placed')]),
    );

    final updated = feed.withOrder(order('o1', 'cancelled'));

    expect(updated.orders.map((order) => order.id), <String>['o1', 'o2']);
    expect(updated.orders.first.group, OrderStatusGroup.cancelled);
    expect(updated.orders.last.group, OrderStatusGroup.inProgress);
  });

  test('an order the feed does not know goes on top', () {
    final feed = OrdersFeed.empty.replace(
      page(<OrderEntity>[order('o2', 'placed')]),
    );

    final updated = feed.withOrder(order('o1', 'placed'));

    expect(updated.orders.map((order) => order.id), <String>['o1', 'o2']);
  });
}
