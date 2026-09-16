import 'package:equatable/equatable.dart';

import 'order.dart';

/// Bucketed order-list snapshot for `mach_pro_sailor_c_order_list` — the two tabs
/// (In progress / History) over the catalogue orders. The active/history split
/// (previously inline in the orders screen `build`) is relocated to the data
/// layer and surfaced here over the framework-free [OrderEntity].
class OrdersView extends Equatable {
  const OrdersView({this.active = const [], this.history = const []});

  /// Orders still in flight (delivering / preparing) — the "In progress" tab.
  final List<OrderEntity> active;

  /// Completed / cancelled orders — the "History" tab.
  final List<OrderEntity> history;

  @override
  List<Object?> get props => [active, history];
}
