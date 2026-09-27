import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/content_page_model.dart';

/// The CMS pages as last shown, per slug and language. Public: the same for
/// every customer. Parsed back with the DTO's own `fromJson`. (The offers
/// keep their copy in the shared `CatalogCacheDataSource`.)
abstract class PromotionsCacheDataSource {
  /// `GET /v1/pages/:slug`.
  CacheSlot<ContentPageModel>? page(String slug);
}

class PromotionsCacheDataSourceImpl implements PromotionsCacheDataSource {
  const PromotionsCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  /// About, contact, FAQ, privacy, terms: they change rarely.
  static const CacheNamespace pageNamespace = CacheNamespace(
    'marketing.page',
    scope: CacheScope.public,
    freshFor: Duration(hours: 1),
    maxAge: Duration(days: 30),
    maxEntries: 10,
  );

  @override
  CacheSlot<ContentPageModel>? page(String slug) => _slots.of(
    pageNamespace,
    id: slug,
    parse: (raw) =>
        ContentPageModel.fromJson(ApiPayload.asMap(raw, EndPoints.page(slug))),
  );
}
