import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/error/failures.dart';

/// Read boundary of category browsing and product listings (jm3eia backend,
/// public routes).
abstract class CatalogBrowseRepository {
  /// `GET /v1/categories` — the whole tree. The app keeps the tree it last
  /// read for the current language; [refresh] asks the backend again.
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  });

  /// `GET /v1/brands` — every brand (the backend caps a page at 100).
  Future<Either<Failure, List<BrandEntity>>> getBrands();

  /// `GET /v1/products` — one page of [query]. [page] is 1-based, [limit] is
  /// capped by the backend at 100.
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  });
}
