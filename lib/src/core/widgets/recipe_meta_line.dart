import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_assets.dart';
import '../responsive/app_size.dart';
import 'hero_svg_glyph.dart';

/// A recipe's time and size in one grey line — the Hero clock and "80 min",
/// the Hero person and "6 servings" ([HeroAssets.sharedClock],
/// [HeroAssets.tabAccount]). The glyphs are decorative: the words say it.
class RecipeMetaLine extends StatelessWidget {
  const RecipeMetaLine({
    super.key,
    required this.minutes,
    required this.servings,
  });

  final int minutes;
  final int servings;

  static const double _glyph = AppSize.s14;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HeroSvgGlyph.mono(
          HeroAssets.sharedClock,
          size: _glyph,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: AppSpacing.s4),
        Flexible(
          child: Text(
            'catalog.recipe_minutes'.tr(namedArgs: {'minutes': '$minutes'}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        const HeroSvgGlyph.mono(
          HeroAssets.tabAccount,
          size: _glyph,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: AppSpacing.s4),
        Flexible(
          child: Text(
            'catalog.recipe_servings'.tr(namedArgs: {'servings': '$servings'}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
