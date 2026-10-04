import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/order_fulfillment_entities.dart';
import '../../../../core/domain/entities/order_status.dart';

/// Where an order's payment stands, as the order page, the invoice page and
/// the invoice PDF word it.
enum OrderPaymentStanding {
  /// The money was taken.
  paid,

  /// A cancelled order that was never paid: nothing is due any more.
  notCharged,

  /// Cash still to hand over when the order arrives.
  dueOnDelivery,

  /// Any other unpaid order.
  pending;

  static OrderPaymentStanding of(
    OrderPaymentEntity payment, {
    required bool cancelled,
  }) {
    if (payment.isPaid) return paid;
    if (cancelled) return notCharged;
    if (payment.method == OrderPaymentMethod.cod) return dueOnDelivery;
    return pending;
  }

  static OrderPaymentStanding ofOrder(OrderEntity order) =>
      of(order.payment, cancelled: order.status == OrderStatus.cancelled);

  /// Its words: the pages translate them, the PDF reads them in the
  /// language it is written in.
  String get labelKey => switch (this) {
    paid => 'orders.payment_paid',
    notCharged => 'orders.payment_not_charged',
    dueOnDelivery => 'orders.payment_due_on_delivery',
    pending => 'orders.payment_pending',
  };
}
