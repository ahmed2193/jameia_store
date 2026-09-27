import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/product_reviews.dart';
import '../../domain/usecases/get_product_reviews_usecase.dart';
import '../../domain/usecases/watch_product_reviews_usecase.dart';
import 'product_reviews_state.dart';

/// The reviews section of a product page
/// (`GET /v1/products/:slug/reviews`), loaded beside the product so it never
/// delays — or blanks — the page. The first page paints from the device copy
/// (offline too), then the server's. "Show more" pages explicitly (a button,
/// not a scroll trigger: the section sits in the middle of the page).
class ProductReviewsCubit extends Cubit<ProductReviewsState>
    with
        SafeCubitMixin<ProductReviewsState>,
        SnapshotLoaderMixin<ProductReviewsState> {
  ProductReviewsCubit(
    this._watchFirstPage,
    this._getReviews, {
    required this._slug,
  }) : super(const ProductReviewsState());

  final WatchProductReviewsUseCase _watchFirstPage;
  final GetProductReviewsUseCase _getReviews;
  final String _slug;

  /// Bumped by every first-page read; a later page asked for an older list
  /// is stale.
  int _generation = 0;

  Future<void> load() {
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: ProductReviewsStatus.loading));
    }
    return _readFirstPage(forceRefresh: false);
  }

  /// The connection came back: a saved or failed first page asks the server
  /// once; otherwise a "show more" that failed is tried again.
  Future<void> onReconnected() {
    final reload =
        state.freshness.isStale || state.status == ProductReviewsStatus.error;
    return refreshOnReconnect(
      needed: reload || state.loadMoreFailed,
      refresh: () => reload ? _readFirstPage(forceRefresh: true) : loadMore(),
    );
  }

  Future<void> _readFirstPage({required bool forceRefresh}) {
    _generation++;
    return followSnapshots<ProductReviews>(
      _watchFirstPage(
        WatchProductReviewsParams(slug: _slug, forceRefresh: forceRefresh),
      ),
      onSnapshot: (snapshot) => safeEmit(
        state.copyWith(
          status: ProductReviewsStatus.loaded,
          reviews: snapshot.data,
          freshness: DataFreshness.of(snapshot),
          loadMoreFailed: false,
        ),
      ),
      onFailure: (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? ProductReviewsStatus.loaded
              : ProductReviewsStatus.error,
          freshness: state.freshness.failed(),
          failure: failure,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (!state.canLoadMore) return;
    final generation = _generation;
    safeEmit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _getReviews(
      GetProductReviewsParams(slug: _slug, page: state.reviews.page + 1),
    );
    // The list was reloaded meanwhile: drop this page, but never leave the
    // loading flag stuck (the reload may have failed without clearing it).
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
          reviews: state.reviews.merge(next),
        ),
      ),
    );
  }
}
