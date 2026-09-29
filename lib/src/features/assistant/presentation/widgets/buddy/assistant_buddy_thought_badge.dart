import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../domain/entities/assistant_thought_topic.dart';
import '../chat/assistant_tool_glyphs.dart';

/// A small tinted disc at the start of the launcher's thought, saying at a
/// glance what the line is about, in the Hero glyph set
/// (docs/motion/asset_manifest.md block 15) — the assistant for hello, a
/// magnifier for finding, the coupon tag for an offer, three jar sizes for
/// choosing, a pot for meals, the home tag for the home… Still: it pops into
/// place only when the [topic] changes (a line handing over to the next),
/// and never rocks or loops (docs/motion §9.6 §3.1 row 9). Reduced motion:
/// it just swaps.
class AssistantBuddyThoughtBadge extends StatelessWidget {
  const AssistantBuddyThoughtBadge({super.key, required this.topic});

  final AssistantThoughtTopic topic;

  static const double _size = AppSize.s24;
  static const double _glyph = AppSize.s14;

  static AssistantToolGlyph glyphOf(
    AssistantThoughtTopic topic,
  ) => switch (topic) {
    AssistantThoughtTopic.greet => const AssistantToolGlyph.svg(
      HeroAssets.assistantAi,
    ),
    AssistantThoughtTopic.find => const AssistantToolGlyph.icon(
      HeroIcons.search,
    ),
    AssistantThoughtTopic.deals => const AssistantToolGlyph.svg(
      HeroAssets.checkoutCodeTag,
    ),
    AssistantThoughtTopic.choose => const AssistantToolGlyph.svg(
      HeroAssets.productOptions,
    ),
    AssistantThoughtTopic.ask => const AssistantToolGlyph.icon(HeroIcons.chat),
    AssistantThoughtTopic.fix => const AssistantToolGlyph.icon(HeroIcons.help),
    AssistantThoughtTopic.home => const AssistantToolGlyph.svg(
      HeroAssets.addressLabelHome,
    ),
    AssistantThoughtTopic.meals => const AssistantToolGlyph.svg(
      HeroAssets.recipePot,
    ),
    AssistantThoughtTopic.cart => const AssistantToolGlyph.icon(HeroIcons.cart),
    AssistantThoughtTopic.company => const AssistantToolGlyph.icon(
      HeroIcons.favorite,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final deal = topic == AssistantThoughtTopic.deals;
    final ink = deal ? AppColors.accent3 : AppColors.primary;
    final glyph = glyphOf(topic);
    return PopSwitcher(
      stateKey: topic,
      child: SizedBox.square(
        dimension: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: deal ? AppColors.accent3Light : AppColors.brandLightBg,
            shape: BoxShape.circle,
          ),
          child: switch (glyph.asset) {
            final String asset => Center(
              child: HeroSvgGlyph.mono(asset, size: _glyph, color: ink),
            ),
            null => Icon(glyph.icon, size: _glyph, color: ink),
          },
        ),
      ),
    );
  }
}
