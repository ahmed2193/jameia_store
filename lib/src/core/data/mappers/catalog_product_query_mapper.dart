import '../../domain/entities/catalog_product_query.dart';

/// [CatalogProductQuery] → the query string of `GET /v1/products`. Only what
/// the query sets is sent; an absent key means "no filter" on the backend.
extension CatalogProductQueryMapper on CatalogProductQuery {
  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String searchField = 'search';
  static const String categorySlugField = 'categorySlug';
  static const String brandSlugField = 'brandSlug';
  static const String collectionSlugField = 'collectionSlug';
  static const String tagField = 'tag';
  static const String inStockField = 'inStock';
  static const String onSaleField = 'onSale';
  static const String minPriceField = 'minPrice';
  static const String maxPriceField = 'maxPrice';
  static const String sortField = 'sort';

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int limit,
  }) => <String, dynamic>{
    pageField: page,
    limitField: limit,
    searchField: ?normalizedSearch,
    categorySlugField: ?_slug(categorySlug),
    brandSlugField: ?_slug(brandSlug),
    collectionSlugField: ?_slug(collectionSlug),
    tagField: ?_slug(tag),
    if (inStockOnly) inStockField: true,
    if (onSaleOnly) onSaleField: true,
    minPriceField: ?minPriceFils,
    maxPriceField: ?maxPriceFils,
    sortField: ?_sortWire(sort),
  };

  static String? _slug(String? value) {
    final slug = value?.trim() ?? '';
    return slug.isEmpty ? null : slug;
  }

  static String? _sortWire(CatalogProductSort? sort) => switch (sort) {
    null => null,
    CatalogProductSort.newest => 'newest',
    CatalogProductSort.priceLowToHigh => 'price_asc',
    CatalogProductSort.priceHighToLow => 'price_desc',
    CatalogProductSort.name => 'name',
    CatalogProductSort.discount => 'discount_desc',
  };
}
