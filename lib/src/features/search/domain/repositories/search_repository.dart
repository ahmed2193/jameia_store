import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/recent_searches.dart';

/// Search boundary: product matches, the category tree and the brands come
/// from the jm3eia backend; the recent terms live on the device.
abstract class SearchRepository {
  /// `GET /v1/products?search=&limit=` — the first [limit] matches.
  Future<Either<Failure, List<CatalogProductEntity>>> suggestProducts({
    required String text,
    required int limit,
  });

  /// `GET /v1/categories` — the whole tree.
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree();

  /// `GET /v1/brands`.
  Future<Either<Failure, List<BrandEntity>>> getBrands();

  Either<Failure, RecentSearches> getRecentSearches();

  Future<Either<Failure, Unit>> saveRecentSearches(RecentSearches recents);
}
