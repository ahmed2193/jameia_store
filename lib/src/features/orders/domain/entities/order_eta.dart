import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/order_fulfillment_entities.dart';
import '../../../../core/domain/entities/order_status.dart';

/// What the big line of the tracking page can honestly say about time.
enum OrderEtaKind {
  /// Nothing to promise (no estimate, a failed delivery, an unknown status).
  none,

  /// On its way to the customer's clock time [OrderEta.at].
  arriving,

  /// A pickup order that should be ready around [OrderEta.at].
  readyAround,

  /// The estimate [OrderEta.at] has passed and the order is still moving.
  late,

  /// A delivery window the customer booked ([OrderEta.slot]).
  window,

  /// Delivered (or picked up) at [OrderEta.at].
  delivered,

  /// Cancelled at [OrderEta.at] (may be unknown).
  cancelled,
}

/// The order's time line, from real fields only: the server's `etaMinutes`
/// counted from when the order was placed, the booked window, or when it
/// was delivered / cancelled. Never a promise: an estimated clock time is
/// rounded UP to [roundToMinutes], as the checkout shows it, and the
/// minutes left are counted against [now] — the page passes a minute clock,
/// so the line moves on its own while the customer watches.
class OrderEta extends Equatable {
  const OrderEta({
    this.kind = OrderEtaKind.none,
    this.at,
    this.minutesLeft,
    this.slot,
    this.took,
  });

  static const OrderEta none = OrderEta();

  /// The estimated clock time is rounded up to this many minutes (the
  /// checkout's rule, so the time a customer saw there is the one here).
  static const int roundToMinutes = 5;

  /// Rules, first match wins: cancelled → when; delivered → when (and how
  /// long it took); a failed delivery or an unknown status → nothing; a
  /// booked window → the window; a server estimate → the rounded clock time,
  /// "late" once it has passed; otherwise nothing.
  factory OrderEta.of(OrderEntity order, DateTime now) {
    switch (order.status) {
      case OrderStatus.cancelled:
        return OrderEta(
          kind: OrderEtaKind.cancelled,
          at:
              order.cancellation?.cancelledAt ??
              _lastAt(order, OrderStatus.cancelled),
        );
      case OrderStatus.delivered:
        final at =
            order.delivery?.deliveredAt ??
            _lastAt(order, OrderStatus.delivered);
        final placed = order.createdAt;
        final took = at != null && placed != null
            ? at.difference(placed)
            : null;
        return OrderEta(
          kind: OrderEtaKind.delivered,
          at: at,
          took: took != null && took > Duration.zero ? took : null,
        );
      case OrderStatus.deliveryFailed:
      case OrderStatus.other:
        return none;
      case OrderStatus.placed:
      case OrderStatus.confirmed:
      case OrderStatus.picking:
      case OrderStatus.ready:
      case OrderStatus.outForDelivery:
        break;
    }
    final slot = order.deliverySlot;
    if (slot != null && !order.isPickup) {
      return OrderEta(kind: OrderEtaKind.window, slot: slot);
    }
    final minutes = order.etaMinutes;
    final placed = order.createdAt;
    if (minutes == null || minutes <= 0 || placed == null) return none;
    // A pickup order that is ready has nothing left to estimate.
    if (order.isPickup && order.status == OrderStatus.ready) return none;
    final at = roundUp(placed.toLocal().add(Duration(minutes: minutes)));
    final left = at.difference(now);
    if (left <= Duration.zero) {
      return OrderEta(kind: OrderEtaKind.late, at: at);
    }
    return OrderEta(
      kind: order.isPickup ? OrderEtaKind.readyAround : OrderEtaKind.arriving,
      at: at,
      minutesLeft: (left.inSeconds / Duration.secondsPerMinute).ceil(),
    );
  }

  /// [time] rounded up to the next [roundToMinutes] boundary (a time on the
  /// boundary, to the second, stays).
  static DateTime roundUp(DateTime time) {
    final exact =
        time.second == 0 && time.millisecond == 0 && time.microsecond == 0;
    final minute = time.minute;
    if (exact && minute % roundToMinutes == 0) return time;
    final floor = DateTime(time.year, time.month, time.day, time.hour, minute);
    final step = roundToMinutes - minute % roundToMinutes;
    return floor.add(Duration(minutes: step));
  }

  /// When the timeline last entered [status].
  static DateTime? _lastAt(OrderEntity order, OrderStatus status) {
    DateTime? at;
    for (final event in order.statusTimeline) {
      if (event.status == status) at = event.at;
    }
    return at;
  }

  final OrderEtaKind kind;

  /// The clock time the line is about (local), or `null` when unknown.
  final DateTime? at;

  /// Whole minutes until [at], at least 1 ([OrderEtaKind.arriving],
  /// [OrderEtaKind.readyAround]).
  final int? minutesLeft;

  /// The booked window ([OrderEtaKind.window]).
  final OrderDeliverySlotEntity? slot;

  /// Placed → delivered ([OrderEtaKind.delivered]), when both are known.
  final Duration? took;

  bool get isLate => kind == OrderEtaKind.late;

  @override
  List<Object?> get props => [kind, at, minutesLeft, slot, took];
}
