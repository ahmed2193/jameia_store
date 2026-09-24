import 'package:flutter/painting.dart';

import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/home_icon.dart';
import '../../domain/entities/home_section_entity.dart';

/// Theme colours of the backend's accent families and section themes.
abstract final class HomeAccentPalette {
  /// Strong colour: icons, promo-card fills.
  static Color strong(HomeAccent accent) => switch (accent) {
    HomeAccent.emerald => AppColors.martGreen,
    HomeAccent.amber => AppColors.accent3,
    HomeAccent.rose => AppColors.finalPrice,
    HomeAccent.violet => AppColors.accentViolet,
    HomeAccent.sky => AppColors.link,
    HomeAccent.orange => AppColors.accent1,
    HomeAccent.zinc => AppColors.labelGrey,
    HomeAccent.none => AppColors.primaryDark,
  };

  /// Light wash: the disc behind a section icon.
  static Color wash(HomeAccent accent) => switch (accent) {
    HomeAccent.emerald => AppColors.martGreenLight,
    HomeAccent.amber => AppColors.accent3Light,
    HomeAccent.rose => AppColors.finalPriceBg,
    HomeAccent.violet => AppColors.accentVioletLight,
    HomeAccent.sky => AppColors.accentSkyLight,
    HomeAccent.orange => AppColors.accent1Light,
    HomeAccent.zinc => AppColors.smallBackground,
    HomeAccent.none => AppColors.brandLightBg,
  };

  /// Background of a themed block: the soft wash the whole block sits on,
  /// so a deals / sale / featured block reads as one card instead of three
  /// unrelated white bands. A standard block stays white.
  static Color blockFill(HomeSectionTheme theme) => switch (theme) {
    HomeSectionTheme.sale => AppColors.finalPriceBg,
    HomeSectionTheme.deals => AppColors.accent3Light,
    HomeSectionTheme.featured => AppColors.accentVioletLight,
    HomeSectionTheme.store || HomeSectionTheme.standard => AppColors.white,
  };

  /// Fill of a promo strip.
  static Color stripFill(HomeSectionTheme theme) => switch (theme) {
    HomeSectionTheme.sale => AppColors.finalPrice,
    HomeSectionTheme.deals => AppColors.accent3Dark,
    HomeSectionTheme.featured => AppColors.accentViolet,
    HomeSectionTheme.store ||
    HomeSectionTheme.standard => AppColors.primaryDark,
  };
}
