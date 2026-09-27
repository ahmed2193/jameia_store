import '../../domain/entities/offer_entity.dart';
import '../models/offer_model.dart';

/// [OfferModel] (wire) → [OfferEntity]. Unknown trigger / reward kinds map to
/// `other`: the backend adds promotion types without an app release. Shared
/// by the offers screen and the product page (which advertises the offers
/// that count its product).
extension OfferMapper on OfferModel {
  OfferEntity toEntity() => OfferEntity(
    id: id,
    name: name,
    description: description,
    triggerType: switch (triggerType) {
      'cart_subtotal' => OfferTriggerType.cartSubtotal,
      'item_quantity' => OfferTriggerType.itemQuantity,
      'category_quantity' => OfferTriggerType.categoryQuantity,
      _ => OfferTriggerType.other,
    },
    minSubtotalFils: triggerMin,
    minQuantity: triggerMinQuantity,
    productId: triggerProductId,
    categoryId: triggerCategoryId,
    rewardType: switch (rewardType) {
      'free_delivery' => OfferRewardType.freeDelivery,
      'percentage_discount' => OfferRewardType.percentageDiscount,
      'fixed_discount' => OfferRewardType.fixedDiscount,
      'free_product' => OfferRewardType.freeProduct,
      _ => OfferRewardType.other,
    },
    percent: rewardPercent,
    maxDiscountFils: rewardMaxDiscount,
    amountFils: rewardAmount,
    freeQuantity: rewardQuantity,
    stackable: stackable,
    endsAt: endsAt,
    branchIds: branchIds,
  );
}

extension OfferListMapper on List<OfferModel> {
  /// Active offers only, the backend's highest priority first.
  List<OfferEntity> toEntities() {
    final active = where(
      (offer) => offer.status == OfferModel.activeStatus,
    ).toList()..sort((a, b) => b.priority.compareTo(a.priority));
    return [for (final offer in active) offer.toEntity()];
  }
}
