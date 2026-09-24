import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/recipe_summary_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/catalog_recipe_tag.dart';
import '../../../../core/widgets/jameia_image.dart';

/// One recipe of the recipe list: photo, title, teaser, tags and
/// "80 min · 6 servings".
class RecipeListTile extends StatelessWidget {
  const RecipeListTile({super.key, required this.recipe, required this.onTap});

  final RecipeSummaryEntity recipe;
  final VoidCallback onTap;

  static const double _image = AppSize.s96;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          0,
          AppSpacing.s12,
          AppSpacing.s8,
        ),
        padding: const EdgeInsets.all(AppSpacing.s10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JameiaImage(
              url: recipe.imageUrl,
              width: _image,
              height: _image,
              radius: AppSize.r10,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  if (recipe.excerpt.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      recipe.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s6),
                  Wrap(
                    spacing: AppSpacing.s4,
                    runSpacing: AppSpacing.s4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (recipe.cuisineName.isNotEmpty)
                        CatalogRecipeTag(label: recipe.cuisineName),
                      if (recipe.dietName.isNotEmpty)
                        CatalogRecipeTag(label: recipe.dietName),
                      Text(
                        'catalog.recipe_meta'.tr(
                          namedArgs: {
                            'minutes': '${recipe.totalMinutes}',
                            'servings': '${recipe.servings}',
                          },
                        ),
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
