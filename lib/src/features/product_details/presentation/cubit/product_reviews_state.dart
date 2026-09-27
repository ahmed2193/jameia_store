import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_reviews.dart';

enum ProductReviewsStatus { initial, loading, loaded, error }

class ProductReviewsState extends Equatable {
  const ProductReviewsState({
    this.status = ProductReviewsStatus.initial,
    this.reviews = ProductReviews.empty,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.freshness = DataFreshness.none,
    this.failure,
  });

  final ProductReviewsStatus status;
  final ProductReviews reviews;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  /// How fresh the first page is (the device copy, a failed refresh …).
  final DataFreshness freshness;

  /// Transient with [ProductReviewsStatus.loaded] (cleared on the next
  /// [copyWith]); with [ProductReviewsStatus.error] the reason, kept while
  /// the status stays `error`. The section localizes it.
  final Failure? failure;

  bool get isLoaded => status == ProductReviewsStatus.loaded;
  bool get isEmpty => isLoaded && reviews.isEmpty;
  bool get canLoadMore => isLoaded && reviews.hasMore && !isLoadingMore;

  ProductReviewsState copyWith({
    ProductReviewsStatus? status,
    ProductReviews? reviews,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    DataFreshness? freshness,
    Failure? failure,
  }) {
    final nextStatus = status ?? this.status;
    return ProductReviewsState(
      status: nextStatus,
      reviews: reviews ?? this.reviews,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      freshness: freshness ?? this.freshness,
      failure:
          failure ??
          (nextStatus == ProductReviewsStatus.error ? this.failure : null),
    );
  }

  @override
  List<Object?> get props => [
    status,
    reviews,
    isLoadingMore,
    loadMoreFailed,
    freshness,
    failure,
  ];
}
