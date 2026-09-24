import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/product_reviews.dart';

enum ProductReviewsStatus { initial, loading, loaded, error }

class ProductReviewsState extends Equatable {
  const ProductReviewsState({
    this.status = ProductReviewsStatus.initial,
    this.reviews = ProductReviews.empty,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
  });

  final ProductReviewsStatus status;
  final ProductReviews reviews;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  /// Transient — cleared on every [copyWith]; the section localizes it.
  final Failure? failure;

  bool get isLoaded => status == ProductReviewsStatus.loaded;
  bool get isEmpty => isLoaded && reviews.isEmpty;
  bool get canLoadMore => isLoaded && reviews.hasMore && !isLoadingMore;

  ProductReviewsState copyWith({
    ProductReviewsStatus? status,
    ProductReviews? reviews,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Failure? failure,
  }) => ProductReviewsState(
    status: status ?? this.status,
    reviews: reviews ?? this.reviews,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    reviews,
    isLoadingMore,
    loadMoreFailed,
    failure,
  ];
}
