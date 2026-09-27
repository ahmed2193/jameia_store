import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/watch_brands_usecase.dart';
import '../../domain/usecases/watch_products_usecase.dart';
import 'product_listing_state.dart';

/// One paginated product list (`GET /v1/products`) — a category, a brand, a
/// collection, the offers… Sorting and filtering are server-side: every change
/// restarts the list at page 1. The first page paints from the device copy
/// when there is one (offline too) and the server's replaces it; the next
/// pages always come from the server.
class ProductListingCubit extends Cubit<ProductListingState>
    with
        SafeCubitMixin<ProductListingState>,
        SnapshotLoaderMixin<ProductListingState>,
        ScreenLoaderMixin<ProductListingState>,
        PagedScreenMixin<ProductListingState> {
  ProductListingCubit(
    this._watchFirstPage,
    this._getProducts,
    this._watchBrands, {
    required CatalogProductQuery query,
  }) : super(
         ProductListingState(
           query: query,
           brandLocked: query.brandSlug != null,
         ),
       );

  static const Object _brandsChannel = #brands;

  final WatchProductsUseCase _watchFirstPage;
  final GetProductsUseCase _getProducts;
  final WatchBrandsUseCase _watchBrands;

  /// First load, retry after a full-screen error, language switch. A list
  /// on screen stays there while it reloads — the skeleton is only for an
  /// empty screen — and a saved copy paints at once.
  Future<void> load() {
    showLoading();
    return _readFirstPage(forceRefresh: false);
  }

  /// Pull-to-refresh: the server's page 1; the list stays on screen and a
  /// failure is transient.
  @override
  Future<void> refresh() => _readFirstPage(forceRefresh: true);

  Future<void> _readFirstPage({required bool forceRefresh}) =>
      readScreen<CatalogProductsPage>(
        _watchFirstPage(
          WatchProductsParams(query: state.query, forceRefresh: forceRefresh),
        ),
        show: (state, snapshot) => state.copyWith(products: snapshot.data),
      );

  /// Called while scrolling near the end. After a failed page it does nothing
  /// until the customer taps retry — or the connection returns — ([retry] =
  /// true): scroll events would otherwise hammer a failing backend.
  @override
  Future<void> loadMore({bool retry = false}) =>
      loadNextPage<CatalogProductsPage>(
        hasMore: state.products.hasMore,
        retry: retry,
        fetch: () => _getProducts(
          GetProductsParams(query: state.query, page: state.products.page + 1),
        ),
        merge: (state, next) =>
            state.copyWith(products: state.products.merge(next)),
      );

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

  /// The brands the filter sheet offers (`GET /v1/brands`): the saved list at
  /// once, then the server's. Read once per screen, the first time the
  /// customer opens the filter; a failure leaves the sheet as it is instead
  /// of breaking the list.
  Future<void> loadBrands() {
    if (state.brands.isNotEmpty || state.isLoadingBrands) {
      return Future<void>.value();
    }
    safeEmit(state.copyWith(isLoadingBrands: true));
    return followSnapshots<List<BrandEntity>>(
      _watchBrands(WatchParams.cached),
      channel: _brandsChannel,
      onSnapshot: (snapshot) => safeEmit(
        state.copyWith(isLoadingBrands: false, brands: snapshot.data),
      ),
      onFailure: (_) => safeEmit(state.copyWith(isLoadingBrands: false)),
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

  /// Another query: the skeleton, then its saved first page if there is one
  /// (offline too), then the server's. A page still on its way for the old
  /// query is dropped.
  Future<void> _restart(CatalogProductQuery query) {
    safeEmit(state.copyWith(query: query, load: ScreenLoad.restarted));
    return _readFirstPage(forceRefresh: false);
  }
}
