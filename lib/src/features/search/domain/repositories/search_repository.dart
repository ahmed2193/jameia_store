import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../entities/recent_searches.dart';

/// Search boundary: product matches, the category tree and the brands come
/// from the jm3eia backend; the recent terms live on the device. The
/// discover blocks paint the device copy first (offline too); suggestions
/// are typed live and never kept.
abstract class SearchRepository {
  /// `GET /v1/products?search=&limit=` — the first [limit] matches.
  Future<Either<Failure, List<CatalogProductEntity>>> suggestProducts({
    required String text,
    required int limit,
  });

  /// `GET /v1/categories` — the whole tree: the saved copy, then the
  /// server's (skipped while the copy is fresh, unless [forceRefresh]).
  Stream<DataSnapshot<CatalogCategoryTree>> watchCategoryTree({
    bool forceRefresh = false,
  });

  /// `GET /v1/brands` — the first page, like [watchCategoryTree].
  Stream<DataSnapshot<List<BrandEntity>>> watchBrands({
    bool forceRefresh = false,
  });

  Either<Failure, RecentSearches> getRecentSearches();

  Future<Either<Failure, Unit>> saveRecentSearches(RecentSearches recents);
}
