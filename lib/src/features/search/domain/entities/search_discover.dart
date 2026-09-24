import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';

/// What the search screen offers before the customer types: the store's
/// top-level categories and its brands. Either list may be empty — a block the
/// backend could not serve simply does not show.
class SearchDiscover extends Equatable {
  const SearchDiscover({
    this.categories = const <CatalogCategoryEntity>[],
    this.brands = const <BrandEntity>[],
  });

  static const SearchDiscover empty = SearchDiscover();

  final List<CatalogCategoryEntity> categories;
  final List<BrandEntity> brands;

  @override
  List<Object?> get props => [categories, brands];
}
