import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// `GET /v1/cart` → `totals`, all in fils. The server computes every discount;
/// the app only formats.
class CartTotalsEntity extends Equatable {
  const CartTotalsEntity({
    this.subtotalFils = 0,
    this.couponDiscountFils = 0,
    this.loyaltyDiscountFils = 0,
    this.offerDiscountFils = 0,
    this.discountFils = 0,
    this.deliveryFeeFils = 0,
    this.freeDelivery = false,
    this.totalFils = 0,
    this.minOrderFils = 0,
    this.meetsMinOrder = true,
    this.baseDeliveryFeeFils = 0,
    this.expressSurchargeFils = 0,
    this.etaMinutes,
  });

  final int subtotalFils;
  final int couponDiscountFils;
  final int loyaltyDiscountFils;
  final int offerDiscountFils;

  /// Every discount together.
  final int discountFils;
  final int deliveryFeeFils;
  final bool freeDelivery;
  final int totalFils;
  final int minOrderFils;
  final bool meetsMinOrder;
  final int baseDeliveryFeeFils;
  final int expressSurchargeFils;
  final int? etaMinutes;

  /// How much more the customer must add to reach the minimum order.
  int get shortfallFils =>
      meetsMinOrder ? 0 : (minOrderFils - subtotalFils).clamp(0, minOrderFils);
  bool get hasDiscount => discountFils > 0;
  bool get hasDeliveryFee => deliveryFeeFils > 0 && !freeDelivery;

  /// The delivery charge without the express surcharge.
  ///
  /// The server's [deliveryFeeFils] is what it charges for delivery in total,
  /// express included, so a summary that also lists [expressSurchargeFils]
  /// must show this part — otherwise the rows add up past [totalFils].
  /// [baseDeliveryFeeFils] is the branch's list price and stays what it is
  /// even when an offer made delivery free, so it cannot be used here.
  int get deliveryFeeWithoutExpressFils =>
      (deliveryFeeFils - expressSurchargeFils).clamp(0, deliveryFeeFils);

  double get subtotalKd => subtotalFils / CatalogProductEntity.filsPerDinar;
  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;
  double get couponDiscountKd =>
      couponDiscountFils / CatalogProductEntity.filsPerDinar;
  double get loyaltyDiscountKd =>
      loyaltyDiscountFils / CatalogProductEntity.filsPerDinar;
  double get offerDiscountKd =>
      offerDiscountFils / CatalogProductEntity.filsPerDinar;
  double get deliveryFeeKd =>
      deliveryFeeFils / CatalogProductEntity.filsPerDinar;
  double get expressSurchargeKd =>
      expressSurchargeFils / CatalogProductEntity.filsPerDinar;
  double get deliveryFeeWithoutExpressKd =>
      deliveryFeeWithoutExpressFils / CatalogProductEntity.filsPerDinar;
  double get totalKd => totalFils / CatalogProductEntity.filsPerDinar;
  double get minOrderKd => minOrderFils / CatalogProductEntity.filsPerDinar;
  double get shortfallKd => shortfallFils / CatalogProductEntity.filsPerDinar;

  /// The same totals with the subtotal re-summed from projected lines; the
  /// discounts stay the server's until it replies (they are never computed
  /// on the device).
  CartTotalsEntity withSubtotal(int subtotalFils) => CartTotalsEntity(
    subtotalFils: subtotalFils,
    couponDiscountFils: couponDiscountFils,
    loyaltyDiscountFils: loyaltyDiscountFils,
    offerDiscountFils: offerDiscountFils,
    discountFils: discountFils,
    deliveryFeeFils: deliveryFeeFils,
    freeDelivery: freeDelivery,
    totalFils: totalFils,
    minOrderFils: minOrderFils,
    meetsMinOrder: minOrderFils <= 0 || subtotalFils >= minOrderFils,
    baseDeliveryFeeFils: baseDeliveryFeeFils,
    expressSurchargeFils: expressSurchargeFils,
    etaMinutes: etaMinutes,
  );

  @override
  List<Object?> get props => [
    subtotalFils,
    couponDiscountFils,
    loyaltyDiscountFils,
    offerDiscountFils,
    discountFils,
    deliveryFeeFils,
    freeDelivery,
    totalFils,
    minOrderFils,
    meetsMinOrder,
    baseDeliveryFeeFils,
    expressSurchargeFils,
    etaMinutes,
  ];
}
