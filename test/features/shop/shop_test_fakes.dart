import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/brand_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:jameia_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/usecase/watch_params.dart';
import 'package:jameia_mart/src/features/shop/domain/repositories/catalog_browse_repository.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_products_usecase.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/watch_brands_usecase.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/watch_products_usecase.dart';

import '../../core/data/snapshot_test_fakes.dart';

export '../../core/data/snapshot_test_fakes.dart';

/// A [CatalogBrowseRepository] built on its `Future` reads: a test overrides
/// the reads it scripts; every `watch…` read answers once, from the
/// network, with what the matching read returns (the device copy is the
/// real repository's business, tested with it).
abstract class FakeCatalogBrowseRepository implements CatalogBrowseRepository {
  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  }) => throw UnimplementedError();

  /// What [watchBrands] answers.
  Future<Either<Failure, List<BrandEntity>>> brands() async =>
      const Right(<BrandEntity>[]);

  @override
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) => throw UnimplementedError();

  @override
  Stream<DataSnapshot<CatalogCategoryTree>> watchCategoryTree({
    bool forceRefresh = false,
  }) => networkRead(getCategoryTree(refresh: forceRefresh));

  @override
  Stream<DataSnapshot<List<BrandEntity>>> watchBrands({
    bool forceRefresh = false,
  }) => networkRead(brands());

  @override
  Stream<DataSnapshot<CatalogProductsPage>> watchFirstPage({
    required CatalogProductQuery query,
    required int limit,
    bool forceRefresh = false,
  }) => networkRead(getProducts(query: query, page: 1, limit: limit));
}

/// The first-page read of a listing served by a products use case fake, so
/// one fake (gated, counting …) answers every page of the list.
class WatchProductsFromGet implements WatchProductsUseCase {
  WatchProductsFromGet(this._getProducts);

  final GetProductsUseCase _getProducts;

  @override
  Stream<DataSnapshot<CatalogProductsPage>> call(WatchProductsParams params) =>
      networkRead(
        _getProducts(
          GetProductsParams(query: params.query, page: 1, limit: params.limit),
        ),
      );
}

/// The brand filter's source for screens that never open it.
class NoBrands implements WatchBrandsUseCase {
  @override
  Stream<DataSnapshot<List<BrandEntity>>> call(WatchParams params) =>
      networkRead(
        Future<Either<Failure, List<BrandEntity>>>.value(
          const Right(<BrandEntity>[]),
        ),
      );
}
