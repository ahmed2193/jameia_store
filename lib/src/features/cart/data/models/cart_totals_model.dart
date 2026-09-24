import '../../../../core/data/models/json_read.dart';

/// `GET /v1/cart` → `totals` (fils).
class CartTotalsModel {
  const CartTotalsModel({
    this.subtotal = 0,
    this.couponDiscount = 0,
    this.loyaltyDiscount = 0,
    this.offerDiscount = 0,
    this.discount = 0,
    this.deliveryFee = 0,
    this.freeDelivery = false,
    this.total = 0,
    this.minOrder = 0,
    this.meetsMinOrder = true,
    this.baseDeliveryFee = 0,
    this.expressSurcharge = 0,
    this.etaMinutes,
  });

  static const String subtotalKey = 'subtotal';
  static const String couponDiscountKey = 'couponDiscount';
  static const String loyaltyDiscountKey = 'loyaltyDiscount';
  static const String offerDiscountKey = 'offerDiscount';
  static const String discountKey = 'discount';
  static const String deliveryFeeKey = 'deliveryFee';
  static const String freeDeliveryKey = 'freeDelivery';
  static const String totalKey = 'total';
  static const String minOrderKey = 'minOrder';
  static const String meetsMinOrderKey = 'meetsMinOrder';
  static const String baseDeliveryFeeKey = 'baseDeliveryFee';
  static const String expressSurchargeKey = 'expressSurcharge';
  static const String etaMinutesKey = 'etaMinutes';

  factory CartTotalsModel.fromJson(Map<String, dynamic> json) =>
      CartTotalsModel(
        subtotal: JsonRead.integer(json[subtotalKey]) ?? 0,
        couponDiscount: JsonRead.integer(json[couponDiscountKey]) ?? 0,
        loyaltyDiscount: JsonRead.integer(json[loyaltyDiscountKey]) ?? 0,
        offerDiscount: JsonRead.integer(json[offerDiscountKey]) ?? 0,
        discount: JsonRead.integer(json[discountKey]) ?? 0,
        deliveryFee: JsonRead.integer(json[deliveryFeeKey]) ?? 0,
        freeDelivery: JsonRead.flag(json[freeDeliveryKey]),
        total: JsonRead.integer(json[totalKey]) ?? 0,
        minOrder: JsonRead.integer(json[minOrderKey]) ?? 0,
        meetsMinOrder: JsonRead.flag(json[meetsMinOrderKey], fallback: true),
        baseDeliveryFee: JsonRead.integer(json[baseDeliveryFeeKey]) ?? 0,
        expressSurcharge: JsonRead.integer(json[expressSurchargeKey]) ?? 0,
        etaMinutes: JsonRead.integer(json[etaMinutesKey]),
      );

  final int subtotal;
  final int couponDiscount;
  final int loyaltyDiscount;
  final int offerDiscount;
  final int discount;
  final int deliveryFee;
  final bool freeDelivery;
  final int total;
  final int minOrder;
  final bool meetsMinOrder;
  final int baseDeliveryFee;
  final int expressSurcharge;
  final int? etaMinutes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    subtotalKey: subtotal,
    couponDiscountKey: couponDiscount,
    loyaltyDiscountKey: loyaltyDiscount,
    offerDiscountKey: offerDiscount,
    discountKey: discount,
    deliveryFeeKey: deliveryFee,
    freeDeliveryKey: freeDelivery,
    totalKey: total,
    minOrderKey: minOrder,
    meetsMinOrderKey: meetsMinOrder,
    baseDeliveryFeeKey: baseDeliveryFee,
    expressSurchargeKey: expressSurcharge,
    if (etaMinutes != null) etaMinutesKey: etaMinutes,
  };
}
