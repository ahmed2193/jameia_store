import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/error/failures.dart';

enum ProductListingStatus { initial, loading, loaded, error }

class ProductListingState extends Equatable {
  const ProductListingState({
    required this.query,
    this.status = ProductListingStatus.initial,
    this.products = CatalogProductsPage.empty,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.brands = const <BrandEntity>[],
    this.isLoadingBrands = false,
    this.brandLocked = false,
    this.failure,
  });

  /// Scope + the customer's sort / filters: what the list asks the backend.
  final CatalogProductQuery query;
  final ProductListingStatus status;
  final CatalogProductsPage products;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  /// Every brand of the store (`GET /v1/brands`), read once the customer
  /// opens the brand filter.
  final List<BrandEntity> brands;
  final bool isLoadingBrands;

  /// The list IS a brand (a brand page, a brand rail): its scope is fixed,
  /// so the brand filter is not offered.
  final bool brandLocked;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == ProductListingStatus.loaded;
  bool get isEmpty => isLoaded && products.isEmpty;
  bool get canLoadMore => isLoaded && products.hasMore && !isLoadingMore;

  /// The name of [slug] once the brands are loaded; the slug itself until
  /// then (and for a brand the store no longer lists).
  String brandNameOf(String slug) {
    for (final brand in brands) {
      if (brand.slug == slug) return brand.name;
    }
    return slug;
  }

  ProductListingState copyWith({
    CatalogProductQuery? query,
    ProductListingStatus? status,
    CatalogProductsPage? products,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    List<BrandEntity>? brands,
    bool? isLoadingBrands,
    Failure? failure,
  }) => ProductListingState(
    query: query ?? this.query,
    status: status ?? this.status,
    products: products ?? this.products,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    brands: brands ?? this.brands,
    isLoadingBrands: isLoadingBrands ?? this.isLoadingBrands,
    brandLocked: brandLocked,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    query,
    status,
    products,
    isLoadingMore,
    loadMoreFailed,
    brands,
    isLoadingBrands,
    brandLocked,
    failure,
  ];
}
