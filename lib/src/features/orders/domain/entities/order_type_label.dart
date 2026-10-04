import '../../../../core/domain/entities/order_entity.dart';

/// How the order reaches the customer, in words: picked up at the store,
/// an express delivery or a plain delivery. The invoice page and the PDF
/// say it the same way.
extension OrderTypeLabel on OrderEntity {
  String get typeLabelKey => switch ((isPickup, express)) {
    (true, _) => 'orders.invoice_pdf_type_pickup',
    (false, true) => 'orders.delivery_express',
    (false, false) => 'orders.invoice_pdf_type_delivery',
  };
}
