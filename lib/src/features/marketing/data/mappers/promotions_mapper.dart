import '../../domain/entities/content_page_entity.dart';
import '../../domain/entities/offer_entity.dart';
import '../models/content_page_model.dart';
import '../models/offer_model.dart';

/// [OfferModel] (wire) → [OfferEntity]. Unknown trigger / reward kinds map to
/// `other`: the backend adds promotion types without an app release.
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

extension ContentPageMapper on ContentPageModel {
  ContentPageEntity toEntity(ContentPageKind kind) =>
      ContentPageEntity(kind: kind, title: title, body: body);
}
