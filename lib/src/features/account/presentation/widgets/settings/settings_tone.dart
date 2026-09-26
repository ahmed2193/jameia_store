import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';

/// Ink + soft fill pair of a settings row's icon badge, so every row gets a
/// calm, distinct tint from the palette.
enum SettingsTone {
  sky(AppColors.link, AppColors.accentSkyLight),
  amber(AppColors.accent3Dark, AppColors.accent3Light),
  green(AppColors.primaryDark, AppColors.brandLightBg),
  violet(AppColors.accentViolet, AppColors.accentVioletLight),
  teal(AppColors.accent2Dark, AppColors.accent2Light),
  neutral(AppColors.primaryText, AppColors.smallBackground),
  danger(AppColors.logoutRed, AppColors.accent1Light);

  const SettingsTone(this.ink, this.fill);

  final Color ink;
  final Color fill;
}
