import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';

/// The colour family of a settings row's icon badge, so every row gets a
/// calm, distinct tint from the palette: [ink] + soft [fill], and the deep
/// [plate] under the badge's white glyph.
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

  /// The badge's `HeroIconPlate` colour (white glyph at 3:1 or more); null
  /// lets the icon's own fill family pick it.
  Color? get plate => switch (this) {
    SettingsTone.sky => AppColors.link,
    SettingsTone.amber => AppColors.accent1,
    SettingsTone.green => AppColors.primaryDark,
    SettingsTone.violet => AppColors.accentViolet,
    SettingsTone.teal => AppColors.accent2Dark,
    SettingsTone.neutral => null,
    SettingsTone.danger => AppColors.logoutRed,
  };
}
