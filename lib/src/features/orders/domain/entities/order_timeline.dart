import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/order_status.dart';

/// "Order updates" on the order page: every status the order went through,
/// oldest first, each with when it happened. A status repeated back to back
/// (a retried write on the server) is told once, at its first time; a status
/// the build does not know is left out.
class OrderTimeline extends Equatable {
  const OrderTimeline(this.events);

  factory OrderTimeline.of(OrderEntity order) {
    final sorted = [...order.statusTimeline]
      ..sort((a, b) => a.at.compareTo(b.at));
    final events = <OrderStatusEvent>[];
    for (final event in sorted) {
      if (event.status == OrderStatus.other) continue;
      if (events.isNotEmpty && events.last.status == event.status) continue;
      events.add(event);
    }
    return OrderTimeline(List.unmodifiable(events));
  }

  final List<OrderStatusEvent> events;

  bool get isEmpty => events.isEmpty;

  @override
  List<Object?> get props => [events];
}
