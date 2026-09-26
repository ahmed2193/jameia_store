import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/data/mappers/order_mapper.dart';
import '../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../domain/entities/assistant_block.dart';
import '../../domain/entities/assistant_cart_snapshot.dart';
import '../../domain/entities/assistant_order_summary.dart';
import '../models/assistant_block_model.dart';
import '../models/assistant_cart_action_item_model.dart';
import '../models/assistant_cart_snapshot_model.dart';
import '../models/assistant_offer_model.dart';
import '../models/assistant_order_summary_model.dart';
import '../models/assistant_slot_day_model.dart';

/// [AssistantBlockModel] (wire) → [AssistantBlock]. Nested catalogue rows go
/// through the core mappers (tag ids filtered — L18, variant pricing — L19).
extension AssistantBlockModelMapper on AssistantBlockModel {
  AssistantBlock toEntity() => switch (this) {
    AssistantTextBlockModel(:final text) => AssistantTextBlock.parse(text),
    AssistantProductsBlockModel(:final products) => AssistantProductsBlock(
      products: products.toEntities(),
    ),
    AssistantProductDetailBlockModel(:final product) =>
      AssistantProductDetailBlock(product: product.toEntity()),
    final AssistantCartActionBlockModel model => AssistantCartActionBlock(
      actionId: model.actionId,
      items: [for (final item in model.items) item.toEntity()],
      status: actionStatusOf(model.status),
      estimatedTotalFils: model.estimatedTotal,
    ),
    AssistantCartSummaryBlockModel(:final cart) => AssistantCartSummaryBlock(
      cart: cart.toEntity(),
    ),
    AssistantOrderBlockModel(:final order, :final isStatusUpdate) =>
      AssistantOrderBlock(
        order: order.toEntity(),
        isStatusUpdate: isStatusUpdate,
      ),
    AssistantOffersBlockModel(:final offers, :final couponCode) =>
      AssistantOffersBlock(
        offers: [for (final offer in offers) offer.toEntity()],
        couponCode: couponCode,
      ),
    AssistantRecipeBlockModel(
      :final recipe,
      :final servings,
      :final ingredientCount,
    ) =>
      AssistantRecipeBlock(
        recipe: recipe.toEntity(),
        servings: servings,
        ingredientCount: ingredientCount,
      ),
    AssistantFaqBlockModel(:final items) => AssistantFaqBlock(
      items: [
        for (final item in items)
          AssistantFaqItem(
            id: item.id,
            question: item.question,
            answer: item.answer,
          ),
      ],
    ),
    AssistantCategoriesBlockModel(:final categories) =>
      AssistantCategoriesBlock(categories: categories.toEntities()),
    AssistantBrandsBlockModel(:final brands) => AssistantBrandsBlock(
      brands: brands.toEntities(),
    ),
    AssistantDeliverySlotsBlockModel(:final days) =>
      AssistantDeliverySlotsBlock(
        days: [for (final day in days) day.toEntity()],
      ),
    final AssistantDeliveryInfoBlockModel model => AssistantDeliveryInfoBlock(
      areaName: model.areaName,
      zoneName: model.zoneName,
      feeFils: model.fee,
      etaMinutes: model.etaMinutes,
    ),
    AssistantLocationsBlockModel(:final items) => AssistantLocationsBlock(
      items: [
        for (final item in items)
          AssistantLocation(
            label: item.label,
            address: item.address,
            phone: item.phone,
            position: GeoPointEntity(lat: item.lat, lng: item.lng),
          ),
      ],
    ),
    AssistantHandoffBlockModel(:final ticketId, :final ticketNumber) =>
      AssistantHandoffBlock(ticketId: ticketId, ticketNumber: ticketNumber),
    AssistantActionsBlockModel(:final suggestions) => AssistantActionsBlock(
      suggestions: [
        for (final suggestion in suggestions)
          AssistantSuggestion(
            label: suggestion.label,
            prompt: suggestion.prompt,
          ),
      ],
    ),
    AssistantErrorBlockModel(:final code, :final message) =>
      AssistantErrorBlock(code: code, message: message),
  };

  static AssistantActionStatus actionStatusOf(String wire) => switch (wire) {
    'pending' => AssistantActionStatus.pending,
    'confirmed' => AssistantActionStatus.confirmed,
    'cancelled' => AssistantActionStatus.cancelled,
    'expired' => AssistantActionStatus.expired,
    _ => AssistantActionStatus.other,
  };
}

extension AssistantBlockListMapper on List<AssistantBlockModel> {
  List<AssistantBlock> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}

extension AssistantCartActionItemMapper on AssistantCartActionItemModel {
  AssistantCartActionItem toEntity() => AssistantCartActionItem(
    productId: productId,
    variantId: variantId,
    quantity: quantity,
    product: product?.toEntity(),
  );
}

extension AssistantCartSnapshotMapper on AssistantCartSnapshotModel {
  AssistantCartSnapshot toEntity() => AssistantCartSnapshot(
    itemCount: itemCount,
    totalFils: total,
    minOrderFils: minOrder,
    meetsMinOrder: meetsMinOrder,
    previews: [
      for (final preview in previews)
        AssistantCartPreviewItem(name: preview.name, imageUrl: preview.image),
    ],
  );
}

extension AssistantOrderSummaryMapper on AssistantOrderSummaryModel {
  AssistantOrderSummary toEntity() => AssistantOrderSummary(
    id: id,
    orderNumber: orderNumber,
    status: OrderMapper.orderStatusOf(status),
    totalFils: total,
    createdAt: createdAt,
    itemCount: itemCount,
    thumbnails: thumbnails
        .take(AssistantOrderSummary.maxThumbnails)
        .toList(growable: false),
  );
}

/// Onto the core [OfferEntity]. The block's order is kept (no marketing
/// sort / active filter: the assistant chose what to show).
extension AssistantOfferMapper on AssistantOfferModel {
  OfferEntity toEntity() => OfferEntity(
    id: id,
    name: name,
    description: description,
    triggerType: triggerTypeOf(triggerType),
    minSubtotalFils: triggerMin,
    minQuantity: triggerMinQuantity,
    rewardType: rewardTypeOf(rewardType),
    percent: rewardPercent,
    maxDiscountFils: rewardMaxDiscount,
    amountFils: rewardAmount,
    freeQuantity: rewardQuantity,
    stackable: stackable,
    endsAt: endsAt,
  );

  static OfferTriggerType triggerTypeOf(String wire) => switch (wire) {
    'cart_subtotal' => OfferTriggerType.cartSubtotal,
    'item_quantity' => OfferTriggerType.itemQuantity,
    'category_quantity' => OfferTriggerType.categoryQuantity,
    _ => OfferTriggerType.other,
  };

  static OfferRewardType rewardTypeOf(String wire) => switch (wire) {
    'free_delivery' => OfferRewardType.freeDelivery,
    'percentage_discount' => OfferRewardType.percentageDiscount,
    'fixed_discount' => OfferRewardType.fixedDiscount,
    'free_product' => OfferRewardType.freeProduct,
    _ => OfferRewardType.other,
  };
}

/// Onto the core delivery-slot entities.
extension AssistantSlotDayMapper on AssistantSlotDayModel {
  DeliverySlotDayEntity toEntity() => DeliverySlotDayEntity(
    date: date,
    label: label,
    slots: [
      for (final slot in slots)
        DeliverySlotEntity(
          templateId: slot.templateId,
          date: slot.date,
          start: slot.start,
          end: slot.end,
          startAt: slot.startAt,
          endAt: slot.endAt,
          label: slot.label,
          capacity: slot.capacity,
          booked: slot.booked,
          remaining: slot.remaining,
          available: slot.available,
        ),
    ],
  );
}
