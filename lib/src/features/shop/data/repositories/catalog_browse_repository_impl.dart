import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_cache_data_source.dart';
import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/catalog_browse_repository.dart';

class CatalogBrowseRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements CatalogBrowseRepository {
  const CatalogBrowseRepositoryImpl(this._catalog, {required this._cache});

  final CatalogRemoteDataSource _catalog;
  final CatalogCacheDataSource _cache;

  static const int _firstPage = 1;
  static const int _maxBrands = 100;

  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  }) => execute(
    () async => (await _catalog.getCategories(refresh: refresh)).toTree(),
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
  Stream<DataSnapshot<CatalogProductsPage>> watchFirstPage({
    required CatalogProductQuery query,
    required int limit,
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.products(query, limit: limit),
    fetch: () =>
        _catalog.fetchProducts(query: query, page: _firstPage, limit: limit),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) => execute(
    () async => (await _catalog.getProducts(
      query: query,
      page: page,
      limit: limit,
    )).toEntity(),
  );
}
