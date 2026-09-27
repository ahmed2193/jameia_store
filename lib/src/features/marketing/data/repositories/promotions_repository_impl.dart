import '../../../../core/data/datasources/catalog_cache_data_source.dart';
import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/offer_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../domain/entities/content_page_entity.dart';
import '../../domain/repositories/promotions_repository.dart';
import '../datasources/promotions_cache_data_source.dart';
import '../datasources/promotions_remote_data_source.dart';
import '../mappers/promotions_mapper.dart';

class PromotionsRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements PromotionsRepository {
  const PromotionsRepositoryImpl(
    this._remote,
    this._catalog, {
    required this._cache,
    required this._catalogCache,
  });

  final PromotionsRemoteDataSource _remote;

  /// The shared catalogue read of the offers, and its device copy.
  final CatalogRemoteDataSource _catalog;
  final PromotionsCacheDataSource _cache;
  final CatalogCacheDataSource _catalogCache;

  @override
  Stream<DataSnapshot<List<OfferEntity>>> watchOffers({
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _catalogCache.offers(),
    fetch: _catalog.fetchOffers,
    toEntity: (models) => models.toEntities(),
    forceRefresh: forceRefresh,
  );

  @override
  Stream<DataSnapshot<ContentPageEntity>> watchContentPage(
    ContentPageKind kind, {
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.page(kind.slug),
    fetch: () => _remote.getPage(kind.slug),
    toEntity: (model) => model.toEntity(kind),
    forceRefresh: forceRefresh,
  );
}
