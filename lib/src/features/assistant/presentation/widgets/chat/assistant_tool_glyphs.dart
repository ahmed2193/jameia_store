import 'package:flutter/widgets.dart';

import '../../../../../core/design/hero_icons.dart';

/// The static glyph beside a running tool's status line (docs/motion §9.6
/// §2.7): what kind of step it is, never animated. The Hero set
/// (docs/motion/asset_manifest.md block 16), all Hero font glyphs: the
/// assistant, clock, tag, recipe pot, "all", search, cart, delivery, help,
/// pin and agent. The delivery van points along the reading direction
/// ([HeroIcons.deliveryDirectional] mirrors itself in RTL).
abstract final class AssistantToolGlyphs {
  static const IconData thinking = HeroIcons.assistant;

  /// "Taking longer…" — the hourglass.
  static const IconData slow = HeroIcons.hourglass;

  static IconData of(String? toolName) => switch (toolName) {
    null => thinking,
    'search_products' || 'get_product' => HeroIcons.search,
    'add_to_cart' || 'get_cart' => HeroIcons.cart,
    'track_order' || 'list_orders' => HeroIcons.deliveryDirectional,
    'list_offers' => HeroIcons.tag,
    'search_recipes' => HeroIcons.recipe,
    'search_faq' => HeroIcons.help,
    'list_categories' || 'list_brands' => HeroIcons.categoryAll,
    'list_delivery_slots' || 'check_delivery' => HeroIcons.clock,
    'list_branches' => HeroIcons.pin,
    'handoff_to_human' => HeroIcons.support,
    _ => thinking,
  };
}
