import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/catalog_browse_repository.dart';

class CatalogBrowseRepositoryImpl
    with BaseRepositoryMixin
    implements CatalogBrowseRepository {
  const CatalogBrowseRepositoryImpl(this._catalog);

  final CatalogRemoteDataSource _catalog;

  static const int _firstPage = 1;
  static const int _maxBrands = 100;

  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  }) => execute(
    () async => (await _catalog.getCategories(refresh: refresh)).toTree(),
  );

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() => execute(
    () async => (await _catalog.getBrands(
      page: _firstPage,
      limit: _maxBrands,
    )).toEntities(),
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
