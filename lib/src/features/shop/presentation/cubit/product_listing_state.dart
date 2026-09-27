import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';

class ProductListingState extends Equatable
    implements ScreenLoadState<ProductListingState> {
  const ProductListingState({
    required this.query,
    this.load = const ScreenLoad(),
    this.products = CatalogProductsPage.empty,
    this.brands = const <BrandEntity>[],
    this.isLoadingBrands = false,
    this.brandLocked = false,
  });

  /// Scope + the customer's sort / filters: what the list asks the backend.
  final CatalogProductQuery query;

  /// The first page's read, its freshness, the next page and the failure
  /// that goes with them (with [LoadPhase.error], offline vs error).
  @override
  final ScreenLoad load;
  final CatalogProductsPage products;

  /// Every brand of the store (`GET /v1/brands`), read once the customer
  /// opens the brand filter.
  final List<BrandEntity> brands;
  final bool isLoadingBrands;

  /// The list IS a brand (a brand page, a brand rail): its scope is fixed,
  /// so the brand filter is not offered.
  final bool brandLocked;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;
  bool get isLoadingMore => load.isLoadingMore;
  bool get loadMoreFailed => load.nextPageFailed;
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

  @override
  ProductListingState withLoad(ScreenLoad load) => copyWith(load: load);

  ProductListingState copyWith({
    CatalogProductQuery? query,
    ScreenLoad? load,
    CatalogProductsPage? products,
    List<BrandEntity>? brands,
    bool? isLoadingBrands,
  }) => ProductListingState(
    query: query ?? this.query,
    load: load ?? this.load.settled(),
    products: products ?? this.products,
    brands: brands ?? this.brands,
    isLoadingBrands: isLoadingBrands ?? this.isLoadingBrands,
    brandLocked: brandLocked,
  );

  @override
  List<Object?> get props => [
    query,
    load,
    products,
    brands,
    isLoadingBrands,
    brandLocked,
  ];
}
