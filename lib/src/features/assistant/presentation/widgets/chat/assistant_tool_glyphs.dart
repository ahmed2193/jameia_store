import 'package:flutter/material.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';

/// One step glyph: a Hero font / Material [icon], or a drawn mono
/// `HeroAssets` SVG ([asset], tinted like the icon).
@immutable
class AssistantToolGlyph {
  const AssistantToolGlyph.icon(IconData this.icon) : asset = null;
  const AssistantToolGlyph.svg(String this.asset) : icon = null;

  final IconData? icon;
  final String? asset;

  @override
  bool operator ==(Object other) =>
      other is AssistantToolGlyph && other.icon == icon && other.asset == asset;

  @override
  int get hashCode => Object.hash(icon, asset);
}

/// The static glyph beside a running tool's status line (docs/motion §9.6
/// §2.7): what kind of step it is, never animated. The Hero set
/// (docs/motion/asset_manifest.md block 16): the drawn assistant / pot /
/// clock / tag / "all" glyphs and the Hero font's search, cart, delivery,
/// help, pin and agent. The delivery van points along the reading
/// direction ([HeroIcons.deliveryDirectional] mirrors itself in RTL).
abstract final class AssistantToolGlyphs {
  static const AssistantToolGlyph thinking = AssistantToolGlyph.svg(
    HeroAssets.assistantAi,
  );

  /// "Taking longer…" — the font has no hourglass.
  static const AssistantToolGlyph slow = AssistantToolGlyph.icon(
    Icons.hourglass_bottom_rounded,
  );

  static AssistantToolGlyph of(String? toolName) => switch (toolName) {
    null => thinking,
    'search_products' ||
    'get_product' => const AssistantToolGlyph.icon(HeroIcons.search),
    'add_to_cart' ||
    'get_cart' => const AssistantToolGlyph.icon(HeroIcons.cart),
    'track_order' || 'list_orders' => const AssistantToolGlyph.icon(
      HeroIcons.deliveryDirectional,
    ),
    'list_offers' => const AssistantToolGlyph.svg(HeroAssets.checkoutCodeTag),
    'search_recipes' => const AssistantToolGlyph.svg(HeroAssets.recipePot),
    'search_faq' => const AssistantToolGlyph.icon(HeroIcons.help),
    'list_categories' ||
    'list_brands' => const AssistantToolGlyph.svg(HeroAssets.categoryAll),
    'list_delivery_slots' ||
    'check_delivery' => const AssistantToolGlyph.svg(HeroAssets.sharedClock),
    'list_branches' => const AssistantToolGlyph.icon(HeroIcons.location),
    'handoff_to_human' => const AssistantToolGlyph.icon(
      HeroIcons.customerService,
    ),
    _ => thinking,
  };
}
