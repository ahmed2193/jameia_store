import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_detail.dart';
import '../entities/product_reviews.dart';

/// Read boundary of the product page (jm3eia backend, public routes).
abstract class ProductDetailsRepository {
  /// `GET /v1/products/:slug`. An unknown slug is
  /// `Left(ServerFailure(statusCode: 404))`.
  Future<Either<Failure, ProductDetail>> getProduct(String slug);

  /// `GET /v1/products/:slug/reviews?page&limit` — one page (1-based) plus the
  /// rating summary.
  Future<Either<Failure, ProductReviews>> getReviews({
    required String slug,
    required int page,
    required int limit,
  });

  /// `GET /v1/offers` — the store's active cart offers, highest priority
  /// first (the buy bar's promo tag). Cached for a few minutes.
  Future<Either<Failure, List<OfferEntity>>> getOffers();
}
