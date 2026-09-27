import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';

/// The catalogue reads checkout shows beside the order: the "deals you
/// might have missed" rail and the store's offers (their terms enrich the
/// cart's offer rows).
abstract class CheckoutCatalogRepository {
  /// Products on sale and in stock, biggest discount first
  /// (`GET /v1/products?onSale&inStock&sort`), the first [limit].
  Future<Either<Failure, List<CatalogProductEntity>>> getRailProducts({
    required int limit,
  });

  /// The store's running offers (`GET /v1/offers`), highest priority first.
  Future<Either<Failure, List<OfferEntity>>> getStoreOffers();
}
