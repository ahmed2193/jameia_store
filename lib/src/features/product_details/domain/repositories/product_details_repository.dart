import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_detail.dart';
import '../entities/product_reviews.dart';

/// Read boundary of the product page (Hero backend, public routes). The
/// product and the first page of its reviews paint from the copy saved on
/// the device first (offline too), then the server's.
abstract class ProductDetailsRepository {
  /// `GET /v1/products/:slug` — the saved copy, then the server's (skipped
  /// while the copy is fresh, unless [forceRefresh]). An unknown slug is a
  /// `ServerFailure(statusCode: 404)` on the error channel.
  Stream<DataSnapshot<ProductDetail>> watchProduct(
    String slug, {
    bool forceRefresh = false,
  });

  /// `GET /v1/products/:slug/reviews` — the FIRST page of [limit] plus the
  /// rating summary, like [watchProduct].
  Stream<DataSnapshot<ProductReviews>> watchReviews({
    required String slug,
    required int limit,
    bool forceRefresh = false,
  });

  /// `GET /v1/products/:slug/reviews?page&limit` — one page (1-based) plus the
  /// rating summary. Never kept on the device.
  Future<Either<Failure, ProductReviews>> getReviews({
    required String slug,
    required int page,
    required int limit,
  });

  /// `GET /v1/offers` — the store's active cart offers, highest priority
  /// first (the buy bar's promo tag). Cached for a few minutes.
  Future<Either<Failure, List<OfferEntity>>> getOffers();
}
