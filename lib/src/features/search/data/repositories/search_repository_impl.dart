import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recent_searches.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_local_data_source.dart';

class SearchRepositoryImpl
    with BaseRepositoryMixin
    implements SearchRepository {
  const SearchRepositoryImpl(this._catalog, this._local);

  final CatalogRemoteDataSource _catalog;
  final SearchLocalDataSource _local;

  static const int _firstPage = 1;
  static const int _maxBrands = 100;

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
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree() =>
      execute(() async => (await _catalog.getCategories()).toTree());

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() => execute(
    () async => (await _catalog.getBrands(
      page: _firstPage,
      limit: _maxBrands,
    )).toEntities(),
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
