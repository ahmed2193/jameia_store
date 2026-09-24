import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import 'orders_page.dart';

/// The orders loaded so far, newest first, de-duplicated by id.
///
/// One flat list: the screen shows every order together and each row carries
/// its own status, so nothing here splits them into status buckets.
class OrdersFeed extends Equatable {
  const OrdersFeed._({
    required this.orders,
    required this.page,
    required this.hasMore,
  });

  factory OrdersFeed.of(
    List<OrderEntity> orders, {
    required int page,
    required bool hasMore,
  }) => OrdersFeed._(orders: orders, page: page, hasMore: hasMore);

  static final OrdersFeed empty = OrdersFeed.of(
    const <OrderEntity>[],
    page: 0,
    hasMore: false,
  );

  final List<OrderEntity> orders;

  /// Last page loaded (`0` = none yet).
  final int page;
  final bool hasMore;

  bool get isEmpty => orders.isEmpty;

  /// First page (or a refresh): the feed becomes this page.
  OrdersFeed replace(OrdersPage next) =>
      OrdersFeed.of(next.orders, page: next.page, hasMore: next.hasMore);

  /// A later page: appended, rows already present are dropped.
  OrdersFeed merge(OrdersPage next) {
    final seen = {for (final order in orders) order.id};
    return OrdersFeed.of(
      [
        ...orders,
        for (final order in next.orders)
          if (seen.add(order.id)) order,
      ],
      page: next.page,
      hasMore: next.hasMore,
    );
  }

  /// One order refreshed (tracking came back, a cancel went through); an
  /// order the feed does not know yet goes on top.
  OrdersFeed withOrder(OrderEntity order) {
    final index = orders.indexWhere((current) => current.id == order.id);
    final updated = index < 0
        ? [order, ...orders]
        : [
            for (var i = 0; i < orders.length; i++)
              if (i == index) order else orders[i],
          ];
    return OrdersFeed.of(updated, page: page, hasMore: hasMore);
  }

  @override
  List<Object?> get props => [orders, page, hasMore];
}
