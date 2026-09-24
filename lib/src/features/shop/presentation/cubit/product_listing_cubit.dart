import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_brands_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import 'product_listing_state.dart';

/// One paginated product list (`GET /v1/products`) — a category, a brand, a
/// collection, the offers… Sorting and filtering are server-side: every change
/// restarts the list at page 1.
class ProductListingCubit extends Cubit<ProductListingState>
    with SafeCubitMixin<ProductListingState> {
  ProductListingCubit(
    this._getProducts,
    this._getBrands, {
    required CatalogProductQuery query,
  }) : super(
         ProductListingState(
           query: query,
           brandLocked: query.brandSlug != null,
         ),
       );

  static const int _firstPage = 1;

  final GetProductsUseCase _getProducts;
  final GetBrandsUseCase _getBrands;

  /// Bumped by every first-page load; a reply from an older generation (an
  /// earlier sort / filter, a page of the previous list) is stale.
  int _generation = 0;

  /// First load, retry after a full-screen error, language switch.
  Future<void> load() async {
    safeEmit(state.copyWith(status: ProductListingStatus.loading));
    await refresh();
  }

  /// Pull-to-refresh: the list stays on screen; a failure is transient.
  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await _getProducts(
      GetProductsParams(query: state.query, page: _firstPage),
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? ProductListingStatus.loaded
              : ProductListingStatus.error,
          failure: failure,
        ),
      ),
      (page) => safeEmit(
        state.copyWith(
          status: ProductListingStatus.loaded,
          products: page,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      ),
    );
  }

  /// Called while scrolling near the end. After a failed page it does nothing
  /// until the customer taps retry ([retry] = true): scroll events would
  /// otherwise hammer a failing backend.
  Future<void> loadMore({bool retry = false}) async {
    if (!state.canLoadMore || (state.loadMoreFailed && !retry)) return;
    final generation = _generation;
    safeEmit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _getProducts(
      GetProductsParams(query: state.query, page: state.products.page + 1),
    );
    // The list was restarted meanwhile: this page belongs to the old one. Drop
    // it, but never leave the loading flag stuck (a pull-to-refresh that
    // failed does not clear it).
    if (generation != _generation) {
      safeEmit(state.copyWith(isLoadingMore: false));
      return;
    }
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
          failure: failure,
        ),
      ),
      (next) => safeEmit(
        state.copyWith(
          isLoadingMore: false,
          products: state.products.merge(next),
        ),
      ),
    );
  }

  /// Browse the products of another category (the customer picked a tab, a
  /// sub-category or a chip). `null` drops the category scope. Sort and
  /// filters survive the move; the list restarts at page 1.
  Future<void> setCategorySlug(String? slug) {
    final next = slug == null || slug.isEmpty ? null : slug;
    if (next == state.query.categorySlug) return Future<void>.value();
    return _restart(
      next == null
          ? state.query.copyWith(clearCategorySlug: true)
          : state.query.copyWith(categorySlug: next),
    );
  }

  /// The brands the filter sheet offers (`GET /v1/brands`). Read once per
  /// screen, the first time the customer opens the filter; a failure leaves
  /// the sheet empty instead of breaking the list.
  Future<void> loadBrands() async {
    if (state.brands.isNotEmpty || state.isLoadingBrands) return;
    safeEmit(state.copyWith(isLoadingBrands: true));
    final result = await _getBrands(const NoParams());
    safeEmit(
      state.copyWith(
        isLoadingBrands: false,
        brands: result.getOrElse(() => const []),
      ),
    );
  }

  /// Filter by one brand (`null` = every brand). Ignored on a list that IS a
  /// brand.
  Future<void> setBrandSlug(String? slug) {
    final next = slug == null || slug.isEmpty ? null : slug;
    if (state.brandLocked || next == state.query.brandSlug) {
      return Future<void>.value();
    }
    return _restart(
      next == null
          ? state.query.copyWith(clearBrandSlug: true)
          : state.query.copyWith(brandSlug: next),
    );
  }

  /// `null` = the backend's default order.
  Future<void> setSort(CatalogProductSort? sort) {
    if (sort == state.query.sort) return Future<void>.value();
    return _restart(
      sort == null
          ? state.query.copyWith(clearSort: true)
          : state.query.copyWith(sort: sort),
    );
  }

  Future<void> toggleInStockOnly() =>
      _restart(state.query.copyWith(inStockOnly: !state.query.inStockOnly));

  Future<void> toggleOnSaleOnly() =>
      _restart(state.query.copyWith(onSaleOnly: !state.query.onSaleOnly));

  Future<void> _restart(CatalogProductQuery query) {
    safeEmit(
      state.copyWith(
        query: query,
        status: ProductListingStatus.loading,
        isLoadingMore: false,
        loadMoreFailed: false,
      ),
    );
    return refresh();
  }
}
