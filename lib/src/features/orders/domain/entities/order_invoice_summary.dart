import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/order_status.dart';

/// What one row of an invoice's payment summary stands for.
enum InvoiceChargeKind {
  subtotal,
  offerDiscount,
  proDiscount,
  couponDiscount,
  loyaltyDiscount,
  deliveryFee;

  /// The row takes money off the subtotal.
  bool get isDeduction => switch (this) {
    offerDiscount || proDiscount || couponDiscount || loyaltyDiscount => true,
    subtotal || deliveryFee => false,
  };

  /// The row's words (the coupon's take its `{code}`): the invoice page
  /// translates them, the PDF reads them in the language it is written in.
  String get labelKey => switch (this) {
    subtotal => 'orders.subtotal',
    offerDiscount => 'orders.offer_discount',
    proDiscount => 'orders.pro_discount',
    couponDiscount => 'orders.coupon_discount',
    loyaltyDiscount => 'orders.loyalty_discount',
    deliveryFee => 'orders.delivery_fee',
  };
}

/// One row of the payment summary, in fils as the server sent it.
class InvoiceCharge extends Equatable {
  const InvoiceCharge(this.kind, this.fils, {this.couponCode = ''});

  final InvoiceChargeKind kind;
  final int fils;

  /// The coupon's code, on [InvoiceChargeKind.couponDiscount] only.
  final String couponCode;

  bool get isDeduction => kind.isDeduction;

  /// The delivery came at no charge: the row says "Free".
  bool get isFree => kind == InvoiceChargeKind.deliveryFee && fils <= 0;

  double get kd => fils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [kind, fils, couponCode];
}

/// The loyalty points the order earns — still [pending] until delivered.
class InvoicePointsNote extends Equatable {
  const InvoicePointsNote({required this.points, required this.pending});

  final int points;
  final bool pending;

  @override
  List<Object?> get props => [points, pending];
}

/// An invoice's payment summary — the server's own figures, never
/// recomputed on the device: which rows show (a deduction only when it took
/// something off), the total, the wallet's share and the points note. The
/// invoice page and the PDF both read it, so they always say the same thing.
class OrderInvoiceSummary extends Equatable {
  const OrderInvoiceSummary({
    required this.charges,
    required this.totalFils,
    this.walletShareFils = 0,
    this.points,
  });

  factory OrderInvoiceSummary.of(OrderEntity order) {
    final coupon = order.coupon;
    final loyalty = order.loyalty;
    // A cancelled or failed order earns nothing.
    final earns =
        loyalty.pointsEarned > 0 &&
        (!order.isTerminal || order.status == OrderStatus.delivered);
    return OrderInvoiceSummary(
      charges: [
        InvoiceCharge(InvoiceChargeKind.subtotal, order.subtotalFils),
        if (order.offerDiscountFils > 0)
          InvoiceCharge(
            InvoiceChargeKind.offerDiscount,
            order.offerDiscountFils,
          ),
        if (order.proDiscountFils > 0)
          InvoiceCharge(InvoiceChargeKind.proDiscount, order.proDiscountFils),
        if (coupon != null)
          InvoiceCharge(
            InvoiceChargeKind.couponDiscount,
            coupon.discountFils,
            couponCode: coupon.code,
          ),
        if (loyalty.discountFils > 0)
          InvoiceCharge(
            InvoiceChargeKind.loyaltyDiscount,
            loyalty.discountFils,
          ),
        InvoiceCharge(InvoiceChargeKind.deliveryFee, order.deliveryFeeFils),
      ],
      totalFils: order.totalFils,
      walletShareFils: order.payment.walletShareFils,
      points: earns
          ? InvoicePointsNote(
              points: loyalty.pointsEarned,
              pending: order.status != OrderStatus.delivered,
            )
          : null,
    );
  }

  final List<InvoiceCharge> charges;
  final int totalFils;

  /// What the wallet covered of a cash order (0 = no part).
  final int walletShareFils;

  /// `null` when the order earns no points.
  final InvoicePointsNote? points;

  double get totalKd => totalFils / CatalogProductEntity.filsPerDinar;
  double get walletShareKd =>
      walletShareFils / CatalogProductEntity.filsPerDinar;

  /// Everything the deductions took off ("You saved …"); 0 = none.
  int get savedFils => charges.fold(
    0,
    (sum, charge) => charge.isDeduction ? sum + charge.fils : sum,
  );
  double get savedKd => savedFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [charges, totalFils, walletShareFils, points];
}
