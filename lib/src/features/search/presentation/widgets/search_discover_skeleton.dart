import 'package:flutter/material.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/widgets/skeletonized.dart';
import 'search_brands_section.dart';
import 'search_categories_section.dart';

/// The discover blocks' first read: the real "Popular categories" grid and
/// "Brands" row drawn as bones (stand-in rows, never tappable), so the
/// blocks land where their skeleton was instead of popping into a blank
/// screen (docs/motion §9.4 #6, B3-01 shaped skeletons).
class SearchDiscoverSkeleton extends StatelessWidget {
  const SearchDiscoverSkeleton({super.key});

  /// Two rows of the category grid and a screen of brand tiles.
  static const int _categoryCount = 8;
  static const int _brandCount = 6;

  static final List<CatalogCategoryEntity> _categories = [
    for (var i = 0; i < _categoryCount; i++)
      CatalogCategoryEntity(id: 'c$i', slug: '', name: 'Category'),
  ];

  static final List<BrandEntity> _brands = [
    for (var i = 0; i < _brandCount; i++)
      BrandEntity(id: 'b$i', slug: '', name: 'Brand'),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Skeletonized(
          loading: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchCategoriesSection(categories: _categories),
              SearchBrandsSection(brands: _brands),
            ],
          ),
        ),
      ),
    );
  }
}
