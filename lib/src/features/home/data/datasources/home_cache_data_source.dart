import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/home_feed_model.dart';
import '../models/home_init_model.dart';

/// The home replies as last shown, per language and per identity: both
/// routes are personalised by the Bearer or the guest cart token, so a
/// customer's copy never reaches a guest (it is wiped on sign-out). Parsed
/// back with the DTOs' own `fromJson`.
abstract class HomeCacheDataSource {
  /// `GET /v1/home`; `null` while the identity is not known yet.
  CacheSlot<HomeFeedModel>? feed();

  /// `GET /v1/init`; `null` while the identity is not known yet.
  CacheSlot<HomeInitModel>? init();
}

class HomeCacheDataSourceImpl implements HomeCacheDataSource {
  const HomeCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  /// The server asks for `max-age=60`: a copy younger than that is shown
  /// without a request.
  static const CacheNamespace feedNamespace = CacheNamespace(
    'home.feed',
    scope: CacheScope.owner,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 7),
  );

  static const CacheNamespace initNamespace = CacheNamespace(
    'home.init',
    scope: CacheScope.owner,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 7),
  );

  @override
  CacheSlot<HomeFeedModel>? feed() => _slots.of(
    feedNamespace,
    parse: (raw) =>
        HomeFeedModel.fromJson(ApiPayload.asMap(raw, EndPoints.home)),
  );

  @override
  CacheSlot<HomeInitModel>? init() => _slots.of(
    initNamespace,
    parse: (raw) =>
        HomeInitModel.fromJson(ApiPayload.asMap(raw, EndPoints.init)),
  );
}
