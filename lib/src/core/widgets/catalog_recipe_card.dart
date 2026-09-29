import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../domain/entities/recipe_summary_entity.dart';
import '../responsive/app_size.dart';
import 'catalog_recipe_tag.dart';
import 'hero_image.dart';
import 'recipe_meta_line.dart';

/// A recipe card (home recipe rail, "recipes using this product", the recipe
/// list): photo with the cuisine / diet tags over it, then the title and
/// "⏱ 80 min · 👤 6 servings" ([RecipeMetaLine]).
class CatalogRecipeCard extends StatelessWidget {
  const CatalogRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  static const double width = AppSize.s200;
  static const double _imageHeight = AppSize.s120;

  final RecipeSummaryEntity recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _imageHeight,
              width: width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HeroImage(url: recipe.imageUrl, radius: AppRadius.card),
                  PositionedDirectional(
                    top: AppSpacing.s6,
                    start: AppSpacing.s6,
                    end: AppSpacing.s6,
                    child: Wrap(
                      spacing: AppSpacing.s4,
                      children: [
                        if (recipe.cuisineName.isNotEmpty)
                          CatalogRecipeTag(label: recipe.cuisineName),
                        if (recipe.dietName.isNotEmpty)
                          CatalogRecipeTag(label: recipe.dietName),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            RecipeMetaLine(
              minutes: recipe.totalMinutes,
              servings: recipe.servings,
            ),
          ],
        ),
      ),
    );
  }
}
