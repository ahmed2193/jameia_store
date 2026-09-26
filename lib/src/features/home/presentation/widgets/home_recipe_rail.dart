import 'package:flutter/material.dart';

import '../../../../core/domain/entities/recipe_summary_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/catalog_recipe_card.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_layout.dart';
import 'home_pressable.dart';
import 'home_reveal_item.dart';
import 'home_section_block.dart';

/// The recipe rail of the home feed: a lazily built horizontal strip.
class HomeRecipeRail extends StatelessWidget {
  const HomeRecipeRail({
    super.key,
    required this.section,
    required this.onOpenRecipe,
    required this.onViewAll,
  });

  final HomeRecipeRailSection section;
  final ValueChanged<RecipeSummaryEntity> onOpenRecipe;
  final VoidCallback onViewAll;

  static const double _height = AppSize.s170;

  @override
  Widget build(BuildContext context) {
    final recipes = section.recipes;
    return HomeSectionBlock(
      section: section,
      onSeeAll: onViewAll,
      child: SizedBox(
        height: _height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: HomeLayout.gutter,
          ),
          itemCount: recipes.length,
          separatorBuilder: (_, _) => const SizedBox(width: HomeLayout.itemGap),
          itemBuilder: (context, index) => HomeRevealItem(
            key: ValueKey(recipes[index].id),
            index: index,
            child: HomePressable(
              child: CatalogRecipeCard(
                recipe: recipes[index],
                onTap: () => onOpenRecipe(recipes[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
