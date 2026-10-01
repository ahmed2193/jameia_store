import 'package:flutter/painting.dart';

import '../../../../../config/theme/app_colors.dart';

/// The colours of the Mine tab's icon tiles, one family per kind of entry
/// (brand green for the store, warm for money and rewards, violet for Pro, …):
/// a soft [background] disc on the quick stats, a deep [plate] under the
/// white glyph of a menu row.
enum MineTone {
  brand(AppColors.brandLightBg, AppColors.primaryDark),
  amber(AppColors.accent4Light, AppColors.accent3Dark),
  orange(AppColors.accent3Light, AppColors.accent3Dark),
  rose(AppColors.accent1Light, AppColors.accent1Dark),
  pro(AppColors.accentVioletLight, AppColors.accentViolet),
  sky(AppColors.accentSkyLight, AppColors.link),
  neutral(AppColors.smallBackground, AppColors.primaryText);

  const MineTone(this.background, this.foreground);

  final Color background;
  final Color foreground;

  /// The menu row's `HeroIconPlate` colour (white glyph at 3:1 or more);
  /// null lets the icon's own fill family pick it.
  Color? get plate => switch (this) {
    MineTone.brand => AppColors.primaryDark,
    MineTone.amber => AppColors.offlineSurface,
    MineTone.orange => AppColors.accent1,
    MineTone.rose => AppColors.accent1Dark,
    MineTone.pro => AppColors.accentViolet,
    MineTone.sky => AppColors.link,
    MineTone.neutral => null,
  };
}
