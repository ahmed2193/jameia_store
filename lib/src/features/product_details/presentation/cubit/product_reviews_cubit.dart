import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_product_reviews_usecase.dart';
import 'product_reviews_state.dart';

/// The reviews section of a product page
/// (`GET /v1/products/:slug/reviews`), loaded beside the product so it never
/// delays — or blanks — the page. "Show more" pages explicitly (a button, not
/// a scroll trigger: the section sits in the middle of the page).
class ProductReviewsCubit extends Cubit<ProductReviewsState>
    with SafeCubitMixin<ProductReviewsState> {
  ProductReviewsCubit(this._getReviews, {required this._slug})
    : super(const ProductReviewsState());

  static const int _firstPage = 1;

  final GetProductReviewsUseCase _getReviews;
  final String _slug;

  /// Bumped by every first-page load; an older reply is stale.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: ProductReviewsStatus.loading));
    }
    final result = await _getReviews(
      GetProductReviewsParams(slug: _slug, page: _firstPage),
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? ProductReviewsStatus.loaded
              : ProductReviewsStatus.error,
          failure: failure,
        ),
      ),
      (reviews) => safeEmit(
        state.copyWith(
          status: ProductReviewsStatus.loaded,
          reviews: reviews,
          isLoadingMore: false,
          loadMoreFailed: false,
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
