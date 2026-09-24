import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/recipe_summary_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/catalog_recipe_card.dart';
import 'pdp_section_card.dart';

/// "Recipes using this product": a lazily built horizontal strip.
class PdpRecipesRail extends StatelessWidget {
  const PdpRecipesRail({
    super.key,
    required this.recipes,
    required this.onOpenRecipe,
  });

  final List<RecipeSummaryEntity> recipes;
  final ValueChanged<RecipeSummaryEntity> onOpenRecipe;

  static const double _height = AppSize.s170;

  @override
  Widget build(BuildContext context) {
    return PdpSectionCard(
      title: 'product.recipes_with_product'.tr(),
      padded: false,
      child: SizedBox(
        height: _height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          itemCount: recipes.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s10),
          itemBuilder: (context, index) => CatalogRecipeCard(
            key: ValueKey(recipes[index].id),
            recipe: recipes[index],
            onTap: () => onOpenRecipe(recipes[index]),
          ),
        ),
      ),
    );
  }
}
