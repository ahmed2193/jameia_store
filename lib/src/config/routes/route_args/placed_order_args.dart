import 'package:flutter/foundation.dart';

/// `extra` of [Routes.orderTracking] right after checkout placed the order:
/// tracking then arrives as a top-level swap (fade through) in place of the
/// checkout, not as a step deeper. Every other entry passes the order id
/// (a `String`).
@immutable
class PlacedOrderArgs {
  const PlacedOrderArgs(this.orderId);

  final String orderId;
}
