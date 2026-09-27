import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';

/// Read boundary of category browsing and product listings (Hero backend,
/// public routes). The screens read the copy saved on the device first
/// (offline too), then the server's; only first pages are kept.
abstract class CatalogBrowseRepository {
  /// `GET /v1/categories` — the whole tree. The app keeps the tree it last
  /// read for the current language; [refresh] asks the backend again.
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  });

  /// `GET /v1/categories` — the saved copy, then the server's (skipped while
  /// the copy is fresh, unless [forceRefresh]).
  Stream<DataSnapshot<CatalogCategoryTree>> watchCategoryTree({
    bool forceRefresh = false,
  });

  /// `GET /v1/brands` — every brand (the backend caps a page at 100), like
  /// [watchCategoryTree].
  Stream<DataSnapshot<List<BrandEntity>>> watchBrands({
    bool forceRefresh = false,
  });

  /// `GET /v1/products` — the FIRST page of [query], [limit] a page, like
  /// [watchCategoryTree].
  Stream<DataSnapshot<CatalogProductsPage>> watchFirstPage({
    required CatalogProductQuery query,
    required int limit,
    bool forceRefresh = false,
  });

  /// `GET /v1/products` — one page of [query]. [page] is 1-based, [limit] is
  /// capped by the backend at 100. Never kept on the device.
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  });
}
