import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/product_detail.dart';
import '../util/product_detail_display.dart';

/// "Recommended Recipes" — a horizontal rail of recipe cards (KeeMart
/// `RecipeCard`): image + green "{kcal} kcal" badge, title, and cook time.
class RecipesRail extends StatelessWidget {
  const RecipesRail({super.key, required this.recipes});
  final List<RecipeVM> recipes;

  static const double _cardW = 150;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, AppSpacing.s10),
          child: Text(
            'product.recommended_recipes'.tr(),
            style: AppTextStyles.headingLarge
                .copyWith(fontWeight: AppTextStyles.bold),
          ),
        ),
        SizedBox(
          height: _cardW + 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16),
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s10),
            itemBuilder: (context, i) => _RecipeCard(recipe: recipes[i]),
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});
  final RecipeVM recipe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: RecipesRail._cardW,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: RecipesRail._cardW,
            height: RecipesRail._cardW * 0.72,
            child: Stack(
              children: [
                KeetaImage(
                  url: recipe.image,
                  width: RecipesRail._cardW,
                  height: RecipesRail._cardW * 0.72,
                  radius: AppRadius.card,
                ),
                PositionedDirectional(
                  top: AppSpacing.s6,
                  start: AppSpacing.s6,
                  child: TagChip(
                    label: 'product.kcal'
                        .tr(namedArgs: {'kcal': '${recipe.kcal}'}),
                    bg: AppColors.martGreenLight,
                    fg: AppColors.martGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            recipe.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: AppTextStyles.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 13, color: AppColors.tertiaryText),
              const SizedBox(width: AppSpacing.s4),
              Text(
                'product.minutes_short'
                    .tr(namedArgs: {'min': '${recipe.minutes}'}),
                style: AppTextStyles.captionLarge
                    .copyWith(color: AppColors.tertiaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
