import 'package:equatable/equatable.dart';

/// Server-side orderings of `GET /v1/products` (`sort`).
enum CatalogProductSort {
  newest,
  priceLowToHigh,
  priceHighToLow,
  name,
  discount,
}

/// What one product listing asks the backend for: a scope (category, brand,
/// collection, tag, free text — any combination), filters and an ordering.
/// Page and limit are not part of it: they belong to the request, the query
/// identifies the list.
class CatalogProductQuery extends Equatable {
  const CatalogProductQuery({
    this.search,
    this.categorySlug,
    this.brandSlug,
    this.collectionSlug,
    this.tag,
    this.inStockOnly = false,
    this.onSaleOnly = false,
    this.minPriceFils,
    this.maxPriceFils,
    this.sort,
  });

  /// Backend limit of `search` and every slug (`len 1..120`).
  static const int maxTextLength = 120;

  /// Backend cap of `limit`.
  static const int maxPageSize = 100;

  final String? search;
  final String? categorySlug;
  final String? brandSlug;
  final String? collectionSlug;
  final String? tag;

  /// Sends `inStock=true`. `false` is never sent: the backend reads it as "no
  /// filter", exactly like leaving it out.
  final bool inStockOnly;
  final bool onSaleOnly;
  final int? minPriceFils;
  final int? maxPriceFils;

  /// `null` = the backend's default order.
  final CatalogProductSort? sort;

  /// Free text trimmed and cut to the backend limit; `null` when blank.
  String? get normalizedSearch {
    final text = search?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.length > maxTextLength
        ? text.substring(0, maxTextLength)
        : text;
  }

  bool get hasFilters =>
      inStockOnly || onSaleOnly || minPriceFils != null || maxPriceFils != null;

  CatalogProductQuery copyWith({
    String? search,
    String? categorySlug,
    bool clearCategorySlug = false,
    String? brandSlug,
    bool clearBrandSlug = false,
    bool? inStockOnly,
    bool? onSaleOnly,
    CatalogProductSort? sort,
    bool clearSort = false,
  }) => CatalogProductQuery(
    search: search ?? this.search,
    categorySlug: clearCategorySlug ? null : categorySlug ?? this.categorySlug,
    brandSlug: clearBrandSlug ? null : brandSlug ?? this.brandSlug,
    collectionSlug: collectionSlug,
    tag: tag,
    inStockOnly: inStockOnly ?? this.inStockOnly,
    onSaleOnly: onSaleOnly ?? this.onSaleOnly,
    minPriceFils: minPriceFils,
    maxPriceFils: maxPriceFils,
    sort: clearSort ? null : sort ?? this.sort,
  );

  @override
  List<Object?> get props => [
    search,
    categorySlug,
    brandSlug,
    collectionSlug,
    tag,
    inStockOnly,
    onSaleOnly,
    minPriceFils,
    maxPriceFils,
    sort,
  ];
}
