import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/widgets/hero_section_header.dart';
import 'search_category_grid.dart';

/// "Popular categories": the store's top-level categories as a grid of photo
/// tiles; a tile opens its category.
class SearchCategoriesSection extends StatelessWidget {
  const SearchCategoriesSection({super.key, required this.categories});

  final List<CatalogCategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeroSectionHeader(title: 'search.popular_categories'.tr()),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: SearchCategoryGrid(categories: categories),
        ),
      ],
    );
  }
}
