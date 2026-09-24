import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/domain/entities/cart_applied_offer_entity.dart';
import '../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/cart_item_request.dart';
import '../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/domain/entities/cart_loyalty_entity.dart';
import '../../../../core/domain/entities/cart_offer_line_entity.dart';
import '../../../../core/domain/entities/cart_offer_progress_entity.dart';
import '../../../../core/domain/entities/cart_totals_entity.dart';
import '../../../../core/domain/entities/offer_reward_entity.dart';
import '../../domain/entities/cart_pending_change.dart';
import '../models/cart_mirror_model.dart';
import '../models/cart_model.dart';

/// `CartModel` (wire) → `CartEntity`.
extension CartMapper on CartModel {
  CartEntity toEntity() => CartEntity(
    cartToken: cartToken,
    itemCount: itemCount,
    fulfillmentMode: FulfillmentMode.fromWire(fulfillmentMode),
    lines: [for (final line in lines) line.toEntity()],
    offerLines: [for (final line in offerLines) line.toEntity()],
    appliedOffers: [for (final offer in appliedOffers) offer.toEntity()],
    offerProgress: [for (final row in offerProgress) row.toEntity()],
    coupon: coupon?.toEntity(),
    loyalty: loyalty.toEntity(),
    expressOffered: expressOffered,
    expressSelected: expressSelected,
    expressEtaMinutes: expressEtaMinutes,
    expressSurchargeOfferedFils: expressSurchargeOffered,
    branchOpen: branchOpen,
    capacityAvailable: capacityAvailable,
    totals: totals.toEntity(),
  );
}

extension CartLineMapper on CartLineModel {
  CartLineEntity toEntity() => CartLineEntity(
    key: key,
    product: product.toEntity(),
    quantity: quantity,
    maxQuantity: maxQuantity,
    unitPriceFils: unitPrice,
    compareAtFils: compareAt,
    lineTotalFils: lineTotal,
    variantId: variantId,
    variantName: variantName,
    issue: switch (issue) {
      null => CartLineIssue.none,
      'out_of_stock' => CartLineIssue.outOfStock,
      'quantity_reduced' => CartLineIssue.quantityReduced,
      'unavailable' => CartLineIssue.unavailable,
      _ => CartLineIssue.other,
    },
  );
}

extension CartOfferLineMapper on CartOfferLineModel {
  CartOfferLineEntity toEntity() => CartOfferLineEntity(
    key: key,
    offerId: offerId,
    offerName: offerName,
    quantity: quantity,
    product: product.toEntity(),
  );
}

extension OfferRewardMapper on OfferRewardModel {
  OfferRewardEntity toEntity() => OfferRewardEntity(
    type: switch (type) {
      'free_delivery' => OfferRewardType.freeDelivery,
      'percentage_discount' => OfferRewardType.percentageDiscount,
      'fixed_discount' => OfferRewardType.fixedDiscount,
      'free_product' => OfferRewardType.freeProduct,
      _ => OfferRewardType.other,
    },
    percent: percent,
    maxDiscountFils: maxDiscount,
    amountFils: amount,
    productId: productId,
    quantity: quantity,
  );
}

extension CartAppliedOfferMapper on CartAppliedOfferModel {
  CartAppliedOfferEntity toEntity() => CartAppliedOfferEntity(
    offerId: offerId,
    name: name,
    discountFils: discount,
    reward: reward.toEntity(),
  );
}

extension CartOfferProgressMapper on CartOfferProgressModel {
  CartOfferProgressEntity toEntity() => CartOfferProgressEntity(
    offerId: offerId,
    name: name,
    kind: switch (kind) {
      'subtotal' => OfferProgressKind.subtotal,
      'item' => OfferProgressKind.item,
      'category' => OfferProgressKind.category,
      _ => OfferProgressKind.other,
    },
    currentValue: currentValue,
    targetValue: targetValue,
    remainingValue: remainingValue,
    contextId: contextId,
    contextName: contextName,
    reward: reward.toEntity(),
    rewardProduct: rewardProduct?.toEntity(),
  );
}

extension CartCouponMapper on CartCouponModel {
  CartCouponEntity toEntity() =>
      CartCouponEntity(code: code, discountFils: discount);
}

extension CartLoyaltyMapper on CartLoyaltyModel {
  CartLoyaltyEntity toEntity() =>
      CartLoyaltyEntity(pointsApplied: pointsApplied, discountFils: discount);
}

extension CartTotalsMapper on CartTotalsModel {
  CartTotalsEntity toEntity() => CartTotalsEntity(
    subtotalFils: subtotal,
    couponDiscountFils: couponDiscount,
    loyaltyDiscountFils: loyaltyDiscount,
    offerDiscountFils: offerDiscount,
    discountFils: discount,
    deliveryFeeFils: deliveryFee,
    freeDelivery: freeDelivery,
    totalFils: total,
    minOrderFils: minOrder,
    meetsMinOrder: meetsMinOrder,
    baseDeliveryFeeFils: baseDeliveryFee,
    expressSurchargeFils: expressSurcharge,
    etaMinutes: etaMinutes,
  );
}

/// `POST /v1/cart/items` → `items[]` row.
extension CartItemRequestMapper on CartItemRequest {
  static const String productIdField = 'productId';
  static const String variantIdField = 'variantId';
  static const String quantityField = 'quantity';

  Map<String, dynamic> toBody() => <String, dynamic>{
    productIdField: productId,
    if (variantId != null) variantIdField: variantId,
    quantityField: quantity,
  };
}

extension CartItemRequestListMapper on List<CartItemRequest> {
  List<Map<String, dynamic>> toBody() => [
    for (final item in this) item.toBody(),
  ];
}

extension CartPendingChangeMapper on CartPendingChange {
  CartPendingChangeModel toModel() => CartPendingChangeModel(
    productId: ref.productId,
    variantId: ref.variantId,
    delta: delta,
    absolute: absolute,
    product: product?.toModel(),
  );
}

extension CartPendingChangeModelMapper on CartPendingChangeModel {
  CartPendingChange toEntity() => CartPendingChange(
    ref: CartLineRef(productId, variantId),
    product: product?.toEntity(),
    delta: delta,
    absolute: absolute,
  );
}

extension CartPendingChangeListMapper on List<CartPendingChangeModel> {
  Map<CartLineRef, CartPendingChange> toEntities() => {
    for (final model in this)
      CartLineRef(model.productId, model.variantId): model.toEntity(),
  };
}
