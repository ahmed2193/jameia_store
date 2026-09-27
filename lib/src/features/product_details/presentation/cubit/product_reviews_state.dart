import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/product_reviews.dart';

class ProductReviewsState extends Equatable
    implements ScreenLoadState<ProductReviewsState> {
  const ProductReviewsState({
    this.load = const ScreenLoad(),
    this.reviews = ProductReviews.empty,
  });

  /// The first page's read, its freshness, "show more" and the failure that
  /// goes with them. The section localizes it.
  @override
  final ScreenLoad load;
  final ProductReviews reviews;

  LoadPhase get status => load.phase;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;
  bool get isLoadingMore => load.isLoadingMore;
  bool get loadMoreFailed => load.nextPageFailed;
  bool get isEmpty => isLoaded && reviews.isEmpty;
  bool get canLoadMore => isLoaded && reviews.hasMore && !isLoadingMore;

  @override
  ProductReviewsState withLoad(ScreenLoad load) => copyWith(load: load);

  ProductReviewsState copyWith({ScreenLoad? load, ProductReviews? reviews}) =>
      ProductReviewsState(
        load: load ?? this.load.settled(),
        reviews: reviews ?? this.reviews,
      );

  @override
  List<Object?> get props => [load, reviews];
}
