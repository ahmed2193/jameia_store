import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_reviews.dart';
import '../repositories/product_details_repository.dart';
import 'get_product_reviews_usecase.dart';

class WatchProductReviewsParams extends Equatable {
  const WatchProductReviewsParams({
    required this.slug,
    this.limit = GetProductReviewsParams.defaultPageSize,
    this.forceRefresh = false,
  });

  final String slug;
  final int limit;

  /// The section asks the server again (reconnect): skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [slug, limit, forceRefresh];
}

/// The first page of a product's reviews and its rating summary
/// (`GET /v1/products/:slug/reviews`): the copy saved on the device first,
/// then the server's; failures on the error channel. The next pages are
/// [GetProductReviewsUseCase]'s — never kept.
class WatchProductReviewsUseCase
    implements
        StreamUseCase<DataSnapshot<ProductReviews>, WatchProductReviewsParams> {
  const WatchProductReviewsUseCase(this._repository);

  final ProductDetailsRepository _repository;

  @override
  Stream<DataSnapshot<ProductReviews>> call(WatchProductReviewsParams params) =>
      _repository.watchReviews(
        slug: params.slug,
        limit: params.limit,
        forceRefresh: params.forceRefresh,
      );
}
