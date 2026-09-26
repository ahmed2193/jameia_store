import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/domain/entities/recipe_summary_entity.dart';
import 'assistant_cart_snapshot.dart';
import 'assistant_order_summary.dart';
import 'assistant_rich_text.dart';

/// A typed card the assistant attaches to a reply (`message.blocks[]`, or a
/// live `block` frame). One subclass per documented `kind`; an unknown kind
/// never reaches the domain (the DTO logs and drops it).
sealed class AssistantBlock extends Equatable {
  const AssistantBlock();

  /// Whether the block has anything to show. An empty card (a
  /// `delivery_info` with no field — L13, a rail with no row) is hidden.
  bool get isVisible => true;
}

/// The cards of a reply — shared by the live turn and the stored message, so
/// both draw the SAME cards and the `message_end` swap moves nothing.
abstract final class AssistantCards {
  /// Drawn as a card: not the prose (`text`), not the chips (`actions`),
  /// not empty.
  static bool isCard(AssistantBlock block) =>
      block is! AssistantTextBlock &&
      block is! AssistantActionsBlock &&
      block.isVisible;

  /// [cards] plus [block]. Adjacent `products` blocks become ONE rail,
  /// de-duplicated by id: every `search_products` call streams its own block
  /// ("butter and eggs" → two one-card rails — N8). Returns [cards] itself
  /// when [block] is not a card.
  static List<AssistantBlock> append(
    List<AssistantBlock> cards,
    AssistantBlock block,
  ) {
    if (!isCard(block)) return cards;
    final last = cards.isEmpty ? null : cards.last;
    if (last is AssistantProductsBlock && block is AssistantProductsBlock) {
      final known = {for (final product in last.products) product.id};
      return [
        ...cards.take(cards.length - 1),
        AssistantProductsBlock(
          products: [
            ...last.products,
            ...block.products.where((product) => known.add(product.id)),
          ],
        ),
      ];
    }
    return [...cards, block];
  }

  /// Every card of [blocks], in order.
  static List<AssistantBlock> of(Iterable<AssistantBlock> blocks) =>
      blocks.fold<List<AssistantBlock>>(const [], append);
}

/// `text`: the reply prose (light markdown, ≤ 8000 chars). The message's
/// `content` carries the same text (L6), so the bubble renders from there.
final class AssistantTextBlock extends AssistantBlock {
  const AssistantTextBlock({required this.text, required this.richText});

  factory AssistantTextBlock.parse(String text) =>
      AssistantTextBlock(text: text, richText: AssistantRichText.parse(text));

  final String text;
  final AssistantRichText richText;

  @override
  bool get isVisible => text.trim().isNotEmpty;

  @override
  List<Object?> get props => [text];
}

/// `products`: a rail of catalogue products.
final class AssistantProductsBlock extends AssistantBlock {
  const AssistantProductsBlock({required this.products});

  final List<CatalogProductEntity> products;

  @override
  bool get isVisible => products.isNotEmpty;

  @override
  List<Object?> get props => [products];
}

/// `product_detail`: one product, shown as a wide card.
final class AssistantProductDetailBlock extends AssistantBlock {
  const AssistantProductDetailBlock({required this.product});

  final CatalogProductEntity product;

  @override
  List<Object?> get props => [product];
}

enum AssistantActionStatus { pending, confirmed, cancelled, expired, other }

/// One line of a cart proposal.
class AssistantCartActionItem extends Equatable {
  const AssistantCartActionItem({
    required this.productId,
    required this.quantity,
    this.variantId,
    this.product,
  });

  final String productId;
  final String? variantId;
  final int quantity;

  /// The product row when the server sent it (the card needs it for the
  /// name and thumbnail; a line without it shows the quantity only).
  final CatalogProductEntity? product;

  @override
  List<Object?> get props => [productId, variantId, quantity, product];
}

/// `cart_action`: a cart change the assistant PROPOSES. Nothing changes until
/// the customer confirms it (`POST /v1/assistant/actions/{actionId}/confirm`).
final class AssistantCartActionBlock extends AssistantBlock {
  const AssistantCartActionBlock({
    required this.actionId,
    required this.items,
    this.status = AssistantActionStatus.pending,
    this.estimatedTotalFils,
  });

  final String actionId;
  final List<AssistantCartActionItem> items;
  final AssistantActionStatus status;

  /// As sent; `null` when the server did not estimate.
  final int? estimatedTotalFils;

  bool get isPending => status == AssistantActionStatus.pending;

  /// `null` when there is nothing worth showing: no estimate, or `0` (the
  /// server prices a product with sizes at 0 until one is chosen).
  double? get estimatedTotalKd {
    final fils = estimatedTotalFils;
    return fils == null || fils <= 0
        ? null
        : fils / CatalogProductEntity.filsPerDinar;
  }

  /// Units across every line ("Add 3 items to cart").
  int get unitCount => items.fold(0, (sum, item) => sum + item.quantity);

  AssistantCartActionBlock withStatus(AssistantActionStatus status) =>
      AssistantCartActionBlock(
        actionId: actionId,
        items: items,
        status: status,
        estimatedTotalFils: estimatedTotalFils,
      );

  @override
  List<Object?> get props => [actionId, items, status, estimatedTotalFils];
}

/// `cart_summary`: the cart as it stood when the block was written.
final class AssistantCartSummaryBlock extends AssistantBlock {
  const AssistantCartSummaryBlock({required this.cart});

  final AssistantCartSnapshot cart;

  @override
  List<Object?> get props => [cart];
}

/// `order` / `order_status`: one of the customer's orders.
final class AssistantOrderBlock extends AssistantBlock {
  const AssistantOrderBlock({required this.order, this.isStatusUpdate = false});

  final AssistantOrderSummary order;

  /// `order_status` (a tracking answer) rather than `order`.
  final bool isStatusUpdate;

  @override
  List<Object?> get props => [order, isStatusUpdate];
}

/// `offers`: running promotions, plus a coupon when the assistant has one.
final class AssistantOffersBlock extends AssistantBlock {
  const AssistantOffersBlock({required this.offers, this.couponCode});

  final List<OfferEntity> offers;
  final String? couponCode;

  bool get hasCoupon => couponCode != null && couponCode!.isNotEmpty;

  @override
  bool get isVisible => offers.isNotEmpty || hasCoupon;

  @override
  List<Object?> get props => [offers, couponCode];
}

/// `recipe`: one recipe, scaled to [servings].
final class AssistantRecipeBlock extends AssistantBlock {
  const AssistantRecipeBlock({
    required this.recipe,
    this.servings = 0,
    this.ingredientCount = 0,
  });

  final RecipeSummaryEntity recipe;
  final int servings;
  final int ingredientCount;

  @override
  List<Object?> get props => [recipe, servings, ingredientCount];
}

class AssistantFaqItem extends Equatable {
  const AssistantFaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;

  @override
  List<Object?> get props => [id, question, answer];
}

/// `faq`: store answers (delivery areas, payment, returns …).
final class AssistantFaqBlock extends AssistantBlock {
  const AssistantFaqBlock({required this.items});

  final List<AssistantFaqItem> items;

  @override
  bool get isVisible => items.isNotEmpty;

  @override
  List<Object?> get props => [items];
}

/// `categories`: a rail of catalogue categories.
final class AssistantCategoriesBlock extends AssistantBlock {
  const AssistantCategoriesBlock({required this.categories});

  final List<CatalogCategoryEntity> categories;

  @override
  bool get isVisible => categories.isNotEmpty;

  @override
  List<Object?> get props => [categories];
}

/// `brands`: a rail of brands.
final class AssistantBrandsBlock extends AssistantBlock {
  const AssistantBrandsBlock({required this.brands});

  final List<BrandEntity> brands;

  @override
  bool get isVisible => brands.isNotEmpty;

  @override
  List<Object?> get props => [brands];
}

/// `delivery_slots`: bookable windows per day. A slot is picked by asking
/// the assistant for it (the checkout books it), never booked from here.
final class AssistantDeliverySlotsBlock extends AssistantBlock {
  const AssistantDeliverySlotsBlock({required this.days});

  final List<DeliverySlotDayEntity> days;

  @override
  bool get isVisible => days.isNotEmpty;

  @override
  List<Object?> get props => [days];
}

/// `delivery_info`: what delivery to the customer's area costs / takes.
final class AssistantDeliveryInfoBlock extends AssistantBlock {
  const AssistantDeliveryInfoBlock({
    this.areaName,
    this.zoneName,
    this.feeFils,
    this.etaMinutes,
  });

  final String? areaName;
  final String? zoneName;
  final int? feeFils;
  final int? etaMinutes;

  bool get hasArea => areaName != null && areaName!.isNotEmpty;
  bool get hasZone => zoneName != null && zoneName!.isNotEmpty;

  /// `0` is a real value: free delivery (N22).
  double? get feeKd {
    final fils = feeFils;
    return fils == null ? null : fils / CatalogProductEntity.filsPerDinar;
  }

  /// The live store sends `{"kind":"delivery_info"}` with nothing in it (L13).
  @override
  bool get isVisible =>
      hasArea || hasZone || feeFils != null || etaMinutes != null;

  @override
  List<Object?> get props => [areaName, zoneName, feeFils, etaMinutes];
}

class AssistantLocation extends Equatable {
  const AssistantLocation({
    required this.label,
    required this.position,
    this.address,
    this.phone,
  });

  final String label;
  final String? address;
  final String? phone;
  final GeoPointEntity position;

  bool get hasPhone => phone != null && phone!.isNotEmpty;

  @override
  List<Object?> get props => [label, address, phone, position];
}

/// `locations`: branches / pick-up points.
final class AssistantLocationsBlock extends AssistantBlock {
  const AssistantLocationsBlock({required this.items});

  final List<AssistantLocation> items;

  @override
  bool get isVisible => items.isNotEmpty;

  @override
  List<Object?> get props => [items];
}

/// `handoff`: the support ticket a human will answer.
final class AssistantHandoffBlock extends AssistantBlock {
  const AssistantHandoffBlock({
    required this.ticketId,
    required this.ticketNumber,
  });

  final String ticketId;
  final String ticketNumber;

  @override
  List<Object?> get props => [ticketId, ticketNumber];
}

/// A follow-up the assistant suggests: [label] is shown, [prompt] is sent.
class AssistantSuggestion extends Equatable {
  const AssistantSuggestion({required this.label, required this.prompt});

  final String label;
  final String prompt;

  @override
  List<Object?> get props => [label, prompt];
}

/// `actions`: suggestion chips. They come only with the finished message
/// (L5), always last.
final class AssistantActionsBlock extends AssistantBlock {
  const AssistantActionsBlock({required this.suggestions});

  final List<AssistantSuggestion> suggestions;

  @override
  bool get isVisible => suggestions.isNotEmpty;

  @override
  List<Object?> get props => [suggestions];
}

/// `error`: a tool or the reply failed in part; [message] is shown as sent.
final class AssistantErrorBlock extends AssistantBlock {
  const AssistantErrorBlock({required this.code, this.message});

  final String code;
  final String? message;

  @override
  List<Object?> get props => [code, message];
}
