import 'package:equatable/equatable.dart';

import 'order.dart';
import 'order_address.dart';

/// Tracking snapshot — one [OrderEntity] plus the user's default delivery
/// [OrderAddressEntity], as resolved for the order-tracking and order-map
/// screens.
class OrderTrackingView extends Equatable {
  const OrderTrackingView({required this.order, required this.address});

  final OrderEntity order;
  final OrderAddressEntity address;

  @override
  List<Object?> get props => [order, address];
}
