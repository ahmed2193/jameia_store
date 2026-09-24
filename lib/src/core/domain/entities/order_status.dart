/// `GET /v1/orders` → `status`. [other] catches a value this build does not
/// know.
enum OrderStatus {
  placed,
  confirmed,
  picking,
  ready,
  outForDelivery,
  delivered,
  deliveryFailed,
  cancelled,
  other;

  /// Nothing more will happen to the order.
  bool get isTerminal => this == delivered || this == cancelled;

  /// The customer may still cancel (`POST /v1/orders/{id}/cancel`).
  bool get isCancellable =>
      this == placed || this == confirmed || this == picking;

  /// The list tab the order belongs to.
  OrderStatusGroup get group => switch (this) {
    delivered => OrderStatusGroup.completed,
    cancelled || deliveryFailed => OrderStatusGroup.cancelled,
    _ => OrderStatusGroup.inProgress,
  };

  /// 0-based step on the tracking progress bar (`null` for a state that is
  /// not a forward step).
  int? get progressStep => switch (this) {
    placed => 0,
    confirmed => 1,
    picking => 2,
    ready => 3,
    outForDelivery => 4,
    delivered => 5,
    _ => null,
  };

  static const int progressSteps = 6;

  /// i18n key of the customer-facing label; widgets call `.tr()` on it.
  String get labelKey => switch (this) {
    placed => 'orders.status_placed',
    confirmed => 'orders.status_confirmed',
    picking => 'orders.status_picking',
    ready => 'orders.status_ready',
    outForDelivery => 'orders.status_out_for_delivery',
    delivered => 'orders.status_delivered',
    deliveryFailed => 'orders.status_delivery_failed',
    cancelled => 'orders.status_cancelled',
    other => 'orders.status_unknown',
  };
}

/// Tabs of the orders list.
enum OrderStatusGroup { inProgress, completed, cancelled }

/// `POST /v1/orders/{id}/cancel` → `reason` — the five values the API takes.
enum CancelOrderReason {
  changedMind('changed_mind'),
  orderedByMistake('ordered_by_mistake'),
  tooSlow('too_slow'),
  foundElsewhere('found_elsewhere'),
  other('other');

  const CancelOrderReason(this.wireValue);
  final String wireValue;
}

/// `cancellation.reason` — includes staff reasons; unknown → [other].
enum OrderCancellationReason {
  changedMind,
  orderedByMistake,
  tooSlow,
  foundElsewhere,
  outOfStock,
  customerUnreachable,
  paymentFailed,
  other,
}

enum OrderCancelledBy { customer, staff, other }

/// `delivery.lastFailureReason`.
enum DeliveryFailureReason {
  customerAbsent,
  refused,
  wrongAddress,
  unreachable,
  other,
  none;

  /// i18n key of the notice shown on the tracking page.
  String get labelKey => switch (this) {
    customerAbsent => 'orders.failure_customer_absent',
    refused => 'orders.failure_refused',
    wrongAddress => 'orders.failure_wrong_address',
    unreachable => 'orders.failure_unreachable',
    other || none => 'orders.failure_other',
  };
}

/// `payment.method` (also the checkout choice; `POST /v1/orders` takes
/// `cod` | `wallet`).
enum OrderPaymentMethod {
  cod('cod'),
  wallet('wallet'),
  other('');

  const OrderPaymentMethod(this.wireValue);
  final String wireValue;
}

enum OrderPaymentStatus { pending, paid, other }
