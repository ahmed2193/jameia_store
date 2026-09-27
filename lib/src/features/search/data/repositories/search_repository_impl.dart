import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_cache_data_source.dart';
import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recent_searches.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_local_data_source.dart';

class SearchRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements SearchRepository {
  const SearchRepositoryImpl(
    this._catalog,
    this._local, {
    required this._cache,
  });

  final CatalogRemoteDataSource _catalog;
  final SearchLocalDataSource _local;
  final CatalogCacheDataSource _cache;

  static const int _firstPage = 1;
  static const int _maxBrands = 100;

  /// Suggestions are typed live: never cached.
  @override
  Future<Either<Failure, List<CatalogProductEntity>>> suggestProducts({
    required String text,
    required int limit,
  }) => execute(
    () async => (await _catalog.getProducts(
      query: CatalogProductQuery(search: text),
      page: _firstPage,
      limit: limit,
    )).items.toEntities(),
  );

  @override
  Stream<DataSnapshot<CatalogCategoryTree>> watchCategoryTree({
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.categories(),
    fetch: _catalog.fetchCategories,
    toEntity: (models) => models.toTree(),
    forceRefresh: forceRefresh,
  );

  @override
  Stream<DataSnapshot<List<BrandEntity>>> watchBrands({
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.brands(limit: _maxBrands),
    fetch: () => _catalog.fetchBrands(page: _firstPage, limit: _maxBrands),
    toEntity: (models) => models.toEntities(),
    forceRefresh: forceRefresh,
  );

  @override
  Either<Failure, RecentSearches> getRecentSearches() =>
      executeSync(() => RecentSearches(_local.readRecentSearches()));

  @override
  Future<Either<Failure, Unit>> saveRecentSearches(RecentSearches recents) =>
      execute(() async {
        await _local.writeRecentSearches(recents.terms);
        return unit;
      });
}
