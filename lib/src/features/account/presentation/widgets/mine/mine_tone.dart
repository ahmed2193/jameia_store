import 'package:flutter/painting.dart';

import '../../../../../config/theme/app_colors.dart';

/// The tinted colour pairs the Mine tab's icon tiles use: a soft [background]
/// with a deeper [foreground] glyph, one family per kind of entry (brand
/// green for the store, warm for money and rewards, violet for Pro, …).
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
}
