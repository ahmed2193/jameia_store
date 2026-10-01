import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/assistant_thought_topic.dart';

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

  static IconData glyphOf(AssistantThoughtTopic topic) => switch (topic) {
    AssistantThoughtTopic.greet => HeroIcons.assistant,
    AssistantThoughtTopic.find => HeroIcons.search,
    AssistantThoughtTopic.deals => HeroIcons.tag,
    AssistantThoughtTopic.choose => HeroIcons.options,
    AssistantThoughtTopic.ask => HeroIcons.chat,
    AssistantThoughtTopic.fix => HeroIcons.help,
    AssistantThoughtTopic.home => HeroIcons.home,
    AssistantThoughtTopic.meals => HeroIcons.recipe,
    AssistantThoughtTopic.cart => HeroIcons.cart,
    AssistantThoughtTopic.company => HeroIcons.heart,
  };

  @override
  Widget build(BuildContext context) {
    final deal = topic == AssistantThoughtTopic.deals;
    final ink = deal ? AppColors.accent3 : AppColors.primary;
    return PopSwitcher(
      stateKey: topic,
      child: SizedBox.square(
        dimension: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: deal ? AppColors.accent3Light : AppColors.brandLightBg,
            shape: BoxShape.circle,
          ),
          child: HeroIcon(glyphOf(topic), size: _glyph, color: ink),
        ),
      ),
    );
  }
}
