import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/offer_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/entities/product_reviews.dart';
import '../../domain/repositories/product_details_repository.dart';
import '../datasources/product_details_cache_data_source.dart';
import '../datasources/product_details_remote_data_source.dart';
import '../mappers/product_detail_mapper.dart';

class ProductDetailsRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements ProductDetailsRepository {
  const ProductDetailsRepositoryImpl(
    this._remote,
    this._catalog, {
    required this._cache,
  });

  final ProductDetailsRemoteDataSource _remote;

  /// The shared catalogue reads (the offers list).
  final CatalogRemoteDataSource _catalog;
  final ProductDetailsCacheDataSource _cache;

  static const int _firstPage = 1;

  @override
  Stream<DataSnapshot<ProductDetail>> watchProduct(
    String slug, {
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.detail(slug),
    fetch: () => _remote.getProduct(slug),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Stream<DataSnapshot<ProductReviews>> watchReviews({
    required String slug,
    required int limit,
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.reviews(slug, limit: limit),
    fetch: () => _remote.getReviews(slug: slug, page: _firstPage, limit: limit),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, ProductReviews>> getReviews({
    required String slug,
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getReviews(
      slug: slug,
      page: page,
      limit: limit,
    )).model.toEntity(),
  );

  @override
  Future<Either<Failure, List<OfferEntity>>> getOffers() =>
      execute(() async => (await _catalog.getOffers()).toEntities());
}
