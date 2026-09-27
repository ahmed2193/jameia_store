import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/product_reviews.dart';
import '../../domain/usecases/get_product_reviews_usecase.dart';
import '../../domain/usecases/watch_product_reviews_usecase.dart';
import 'product_reviews_state.dart';

/// The reviews section of a product page
/// (`GET /v1/products/:slug/reviews`), loaded beside the product so it never
/// delays — or blanks — the page. The first page paints from the device copy
/// (offline too), then the server's. "Show more" pages explicitly (a button,
/// not a scroll trigger: the section sits in the middle of the page). The
/// screen and paging flow is the loader mixins'.
class ProductReviewsCubit extends Cubit<ProductReviewsState>
    with
        SafeCubitMixin<ProductReviewsState>,
        SnapshotLoaderMixin<ProductReviewsState>,
        ScreenLoaderMixin<ProductReviewsState>,
        PagedScreenMixin<ProductReviewsState> {
  ProductReviewsCubit(
    this._watchFirstPage,
    this._getReviews, {
    required this._slug,
  }) : super(const ProductReviewsState());

  final WatchProductReviewsUseCase _watchFirstPage;
  final GetProductReviewsUseCase _getReviews;
  final String _slug;

  Future<void> load() {
    showLoading();
    return _readFirstPage(forceRefresh: false);
  }

  /// The server's first page (the reconnect refresh of a saved or failed
  /// one).
  @override
  Future<void> refresh() => _readFirstPage(forceRefresh: true);

  Future<void> _readFirstPage({required bool forceRefresh}) =>
      readScreen<ProductReviews>(
        _watchFirstPage(
          WatchProductReviewsParams(slug: _slug, forceRefresh: forceRefresh),
        ),
        show: (state, snapshot) => state.copyWith(reviews: snapshot.data),
      );

  /// "Show more" (a tap is always an explicit ask: [retry] after a failed
  /// page too).
  @override
  Future<void> loadMore({bool retry = false}) => loadNextPage<ProductReviews>(
    hasMore: state.reviews.hasMore,
    retry: retry,
    fetch: () => _getReviews(
      GetProductReviewsParams(slug: _slug, page: state.reviews.page + 1),
    ),
    merge: (state, next) => state.copyWith(reviews: state.reviews.merge(next)),
  );
}
