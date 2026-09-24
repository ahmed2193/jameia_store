import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_reviews.dart';
import '../repositories/product_details_repository.dart';

class GetProductReviewsParams extends Equatable {
  const GetProductReviewsParams({
    required this.slug,
    required this.page,
    this.limit = defaultPageSize,
  });

  static const int defaultPageSize = 10;

  final String slug;

  /// 1-based.
  final int page;
  final int limit;

  @override
  List<Object?> get props => [slug, page, limit];
}

/// Loads one page of a product's reviews
/// (`GET /v1/products/:slug/reviews`).
class GetProductReviewsUseCase
    implements UseCase<ProductReviews, GetProductReviewsParams> {
  const GetProductReviewsUseCase(this._repository);

  final ProductDetailsRepository _repository;

  @override
  Future<Either<Failure, ProductReviews>> call(
    GetProductReviewsParams params,
  ) => _repository.getReviews(
    slug: params.slug,
    page: params.page,
    limit: params.limit,
  );
}
