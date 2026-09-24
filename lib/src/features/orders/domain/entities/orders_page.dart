import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';

/// One page of `GET /v1/orders`.
class OrdersPage extends Equatable {
  const OrdersPage({
    required this.orders,
    required this.page,
    this.hasMore = false,
    this.total = 0,
  });

  final List<OrderEntity> orders;
  final int page;
  final bool hasMore;
  final int total;

  @override
  List<Object?> get props => [orders, page, hasMore, total];
}
