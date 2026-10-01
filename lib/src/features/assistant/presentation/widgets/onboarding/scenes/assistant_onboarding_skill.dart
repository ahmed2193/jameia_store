import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../core/design/hero_icons.dart';

/// What the hello demo says the assistant does — across a store that has
/// whatever a home needs — each with its glyph, its colours and the spot it
/// lands on around the waving hand (start / end follow the reading
/// direction).
enum AssistantOnboardingSkill {
  find(
    'assistant.onboarding_skill_find',
    HeroIcons.search,
    AppColors.link,
    AppColors.accentSkyLight,
    AlignmentDirectional(-0.96, -0.9),
  ),
  cart(
    'assistant.onboarding_skill_cart',
    HeroIcons.basket,
    AppColors.primaryDark,
    AppColors.brandLightBg,
    AlignmentDirectional(0.96, -0.9),
  ),
  deals(
    'assistant.onboarding_skill_deals',
    HeroIcons.tag,
    AppColors.accent1,
    AppColors.accent1Light,
    AlignmentDirectional(-0.96, 0.2),
  ),
  orders(
    'assistant.onboarding_skill_orders',
    HeroIcons.delivery,
    AppColors.accent3,
    AppColors.accent3Light,
    AlignmentDirectional(0.96, 0.2),
  ),
  home(
    'assistant.onboarding_skill_home',
    HeroIcons.homeFill,
    AppColors.accentViolet,
    AppColors.accentVioletLight,
    AlignmentDirectional(0, 0.96),
  );

  const AssistantOnboardingSkill(
    this.labelKey,
    this.icon,
    this.color,
    this.tint,
    this.spot,
  );

  final String labelKey;
  final IconData icon;
  final Color color;
  final Color tint;
  final AlignmentDirectional spot;
}
