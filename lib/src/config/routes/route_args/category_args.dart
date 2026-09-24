import 'package:flutter/foundation.dart';

import '../../../core/domain/entities/catalog_category_entity.dart';

/// `extra` for [Routes.category]. The category is addressed by [slug]
/// (`GET /v1/categories/:slug`, `GET /v1/products?categorySlug=`); [name] is
/// the title to show while it loads.
@immutable
class CategoryArgs {
  const CategoryArgs({required this.slug, this.name = ''});

  CategoryArgs.of(CatalogCategoryEntity category)
    : slug = category.slug,
      name = category.name;

  final String slug;
  final String name;
}
