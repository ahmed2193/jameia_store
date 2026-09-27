import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';

/// What the tour's demos shop for: a starter kit for a new home, picked
/// from different aisles — cleaning, home, groceries — because the store
/// has whatever a home needs. Each with its glyph, colours and quantity.
enum AssistantOnboardingItem {
  cleaner(
    'assistant.onboarding_demo_cleaner',
    Icons.cleaning_services_rounded,
    AppColors.accentViolet,
    AppColors.accentVioletLight,
    2,
  ),
  bulbs(
    'assistant.onboarding_demo_bulbs',
    Icons.lightbulb_rounded,
    AppColors.accent3,
    AppColors.accent3Light,
    1,
  ),
  coffee(
    'assistant.onboarding_demo_coffee',
    Icons.coffee_rounded,
    AppColors.accent4Foreground,
    AppColors.accent4Light,
    1,
  );

  const AssistantOnboardingItem(
    this.labelKey,
    this.icon,
    this.color,
    this.tint,
    this.quantity,
  );

  final String labelKey;
  final IconData icon;
  final Color color;
  final Color tint;
  final int quantity;

  /// Everything the demo cart receives.
  static int get totalQuantity =>
      values.fold(0, (sum, item) => sum + item.quantity);
}
