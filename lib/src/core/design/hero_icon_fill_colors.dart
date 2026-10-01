import 'dart:ui' show Color;

import '../../config/theme/app_colors.dart';
import 'hero_icons.dart';

/// The [AppColors] behind each [HeroIconFill] (the generated icon file stays
/// theme-free, so the mapping lives here).
extension HeroIconFillColors on HeroIconFill {
  /// The accent layer's colour under the ink line of a sticker icon
  /// (`HeroIcon`): the natural fill of the matching art in `assets/svg`.
  Color get color => switch (this) {
    HeroIconFill.green => AppColors.primary,
    HeroIconFill.mint => AppColors.brandLightBg,
    HeroIconFill.amber => AppColors.proAmber,
    HeroIconFill.yellow => AppColors.accent4,
    HeroIconFill.orange => AppColors.accent3,
    HeroIconFill.red => AppColors.accent1,
    HeroIconFill.sky => AppColors.accentSkyLight,
    HeroIconFill.violet => AppColors.accentVioletLight,
    HeroIconFill.cream => AppColors.collectionCream,
  };

  /// The tile colour of a `HeroIconPlate`: the fill's family, deep enough
  /// that the plate's white glyph reaches at least 3:1 (large-glyph contrast).
  Color get plate => switch (this) {
    HeroIconFill.green => AppColors.primaryDark, // 3.3:1
    HeroIconFill.mint => AppColors.brandDeep, // 5.0:1
    HeroIconFill.amber => AppColors.offlineSurface, // 14.7:1
    HeroIconFill.yellow => AppColors.accent1, // 3.2:1
    HeroIconFill.orange => AppColors.accent1, // 3.2:1
    HeroIconFill.red => AppColors.accent1Dark, // 4.0:1
    HeroIconFill.sky => AppColors.link, // 5.7:1
    HeroIconFill.violet => AppColors.proIndigo, // 6.3:1
    HeroIconFill.cream => AppColors.offlineSurface, // 14.7:1
  };
}
