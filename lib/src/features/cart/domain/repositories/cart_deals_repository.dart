import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';

/// What the "Buy more, save more" sheet lists under an offer (the shared
/// catalogue routes, public).
abstract class CartDealsRepository {
  /// In-stock products to add towards a deal, deepest discount first: the
  /// products of [categoryId] for an offer that counts one category, else
  /// the store's products on sale. A category the tree does not know falls
  /// back to the products on sale.
  Future<Either<Failure, List<CatalogProductEntity>>> getDealProducts({
    String? categoryId,
    required int limit,
  });
}
