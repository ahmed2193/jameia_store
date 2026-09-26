import 'package:flutter/material.dart';

import '../../../domain/entities/assistant_block.dart';
import 'assistant_brands_rail.dart';
import 'assistant_cart_action_card.dart';
import 'assistant_cart_summary_card.dart';
import 'assistant_categories_rail.dart';
import 'assistant_delivery_info_card.dart';
import 'assistant_delivery_slots_card.dart';
import 'assistant_error_card.dart';
import 'assistant_faq_card.dart';
import 'assistant_handoff_card.dart';
import 'assistant_locations_card.dart';
import 'assistant_offers_card.dart';
import 'assistant_order_card.dart';
import 'assistant_product_detail_card.dart';
import 'assistant_products_rail.dart';
import 'assistant_recipe_block_card.dart';

/// One card of a reply, by kind (the sealed switch: a new kind fails to
/// compile until it has a card). Text and chips are drawn by the reply
/// itself, never as cards.
class AssistantBlockView extends StatelessWidget {
  const AssistantBlockView({super.key, required this.block, this.live = false});

  final AssistantBlock block;

  /// The reply is still streaming.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final card = block;
    return switch (card) {
      AssistantProductsBlock(:final products) => AssistantProductsRail(
        products: products,
      ),
      AssistantProductDetailBlock(:final product) => AssistantProductDetailCard(
        product: product,
      ),
      AssistantCartActionBlock() => AssistantCartActionCard(
        block: card,
        live: live,
      ),
      AssistantCartSummaryBlock(:final cart) => AssistantCartSummaryCard(
        cart: cart,
      ),
      AssistantOrderBlock() => AssistantOrderCard(block: card),
      AssistantOffersBlock() => AssistantOffersCard(block: card),
      AssistantRecipeBlock() => AssistantRecipeBlockCard(block: card),
      AssistantFaqBlock(:final items) => AssistantFaqCard(items: items),
      AssistantCategoriesBlock(:final categories) => AssistantCategoriesRail(
        categories: categories,
      ),
      AssistantBrandsBlock(:final brands) => AssistantBrandsRail(
        brands: brands,
      ),
      AssistantDeliverySlotsBlock(:final days) => AssistantDeliverySlotsCard(
        days: days,
      ),
      AssistantDeliveryInfoBlock() => AssistantDeliveryInfoCard(block: card),
      AssistantLocationsBlock(:final items) => AssistantLocationsCard(
        items: items,
      ),
      AssistantHandoffBlock() => AssistantHandoffCard(block: card),
      AssistantErrorBlock() => AssistantErrorCard(block: card),
      AssistantTextBlock() ||
      AssistantActionsBlock() => const SizedBox.shrink(),
    };
  }
}
