import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_env.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/data/datasources/catalog_cache_data_source.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/data/hero_repository.dart';
import '../../core/network/api_base_options.dart';
import '../../core/network/api_consumer.dart';
import '../../core/network/dio_consumer.dart';
import '../../core/network/event_stream_client.dart';
import '../../core/network/interceptors/app_headers_interceptor.dart';
import '../../core/network/interceptors/auth_interceptor.dart';
import '../../core/network/interceptors/network_log_interceptor.dart';
import '../../core/network/interceptors/rate_limit_retry_interceptor.dart';
import '../../core/network/interceptors/reachability_signal_interceptor.dart';
import '../../core/network/locale_provider.dart';
import '../../core/network/network_info.dart';
import '../../core/network/session_expiry_notifier.dart';
import '../../core/network/token_refresher.dart';
import '../../core/storage/cache_owner.dart';
import '../../core/storage/json_cache_store.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/session_store.dart';
import '../../features/account/account_injection_container.dart';
import '../../features/address/address_injection_container.dart';
import '../../features/assistant/assistant_injection_container.dart';
import '../../features/auth/auth_injection_container.dart';
import '../../features/cart/cart_injection_container.dart';
import '../../features/checkout/checkout_injection_container.dart';
import '../../features/connectivity/connectivity_injection_container.dart';
import '../../features/coupons/coupons_injection_container.dart';
import '../../features/home/home_injection_container.dart';
import '../../features/language/language_injection_container.dart';
import '../../features/marketing/marketing_injection_container.dart';
import '../../features/notifications/notifications_injection_container.dart';
import '../../features/orders/orders_injection_container.dart';
import '../../features/product_details/product_details_injection_container.dart';
import '../../features/recipes/recipes_injection_container.dart';
import '../../features/search/search_injection_container.dart';
import '../../features/shop/shop_injection_container.dart';
import '../../features/store_mode/store_mode_injection_container.dart';
import '../../features/support/support_injection_container.dart';

/// The single `get_it` root and the app's DI composition root.
///
/// Lifecycle invariants:
///   * datasources / repositories / use cases → `registerLazySingleton`
///     (interfaces bound to their implementation);
///   * cubits → `registerFactory` (fresh per `BlocProvider` mount);
///   * every class receives its collaborators through its constructor —
///     `sl` is only read here and inside `<feature>_injection_container.dart`.
final GetIt sl = GetIt.instance;

/// Registers core infrastructure, then every feature. Called once from
/// `main.dart` before `runApp`. Each `init<Feature>Feature` is idempotent.
Future<void> setupServiceLocator() async {
  await _initCore();
  await _initFeatures();
}

Future<void> _initCore() async {
  // Offline catalogue — loaded once before the first frame.
  if (!sl.isRegistered<HeroRepository>()) {
    final repo = HeroRepository();
    await repo.load();
    sl.registerSingleton<HeroRepository>(repo);
  }

  await _initStorage();

  _initSession();
  _initNetwork();
  _initCache();
  _initCatalog();
}

/// The shared [LocalStorage] (and its backing [SharedPreferences]), registered
/// once BEFORE any feature init: features only ever resolve
/// `sl<LocalStorage>()`, so they never depend on each other's order.
Future<void> _initStorage() async {
  if (sl.isRegistered<LocalStorage>()) return; // idempotent
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<LocalStorage>(LocalStorageImpl(prefs));
}

/// The on-device response cache (one file per key under the app's cache
/// folder, resolved on first use — app start never waits for it), whose
/// data it may hold, and the slot factory every cache datasource uses. A
/// test registers an in-memory store first.
void _initCache() {
  if (!sl.isRegistered<JsonCacheStore>()) {
    sl.registerLazySingleton<JsonCacheStore>(FileJsonCacheStore.new);
  }
  if (sl.isRegistered<CacheSlots>()) return;
  sl
    ..registerLazySingleton<CacheOwner>(CacheOwner.new)
    ..registerLazySingleton<CacheSlots>(
      () => CacheSlots(
        store: sl<JsonCacheStore>(),
        owner: sl<CacheOwner>(),
        locale: sl<LocaleProvider>(),
      ),
    );
}

/// Catalogue reads shared by several features (product list, category tree,
/// brand list) and their device copies — see [CatalogRemoteDataSource],
/// [CatalogCacheDataSource].
void _initCatalog() {
  if (sl.isRegistered<CatalogRemoteDataSource>()) return;
  sl
    ..registerLazySingleton<CatalogRemoteDataSource>(
      () =>
          CatalogRemoteDataSourceImpl(sl<ApiConsumer>(), sl<LocaleProvider>()),
    )
    ..registerLazySingleton<CatalogCacheDataSource>(
      () => CatalogCacheDataSourceImpl(sl<CacheSlots>()),
    );
}

/// Keychain-backed API session (token pair + guest identities) and the
/// process-wide "session expired" signal.
void _initSession() {
  if (sl.isRegistered<SessionStore>()) return;
  sl.registerLazySingleton<FlutterSecureStorage>(FlutterSecureStorage.new);
  sl.registerLazySingleton<SessionStore>(
    () => SecureSessionStore(sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<SessionExpiryNotifier>(
    SessionExpiryNotifierImpl.new,
  );
}

/// The one Dio behind [ApiConsumer] plus everything its interceptors need.
/// Interceptor ORDER is the contract: auth (Bearer + pre-flight / 401 refresh)
/// → app headers (language / guest identities) → 429 backoff → reachability
/// signals (any response = reachable, a transport failure = re-check) →
/// debug trace.
void _initNetwork() {
  if (sl.isRegistered<ApiConsumer>()) return;
  // One trace for every client so request numbers stay in one sequence.
  final NetworkLogInterceptor? trace = kDebugMode
      ? NetworkLogInterceptor()
      : null;
  // A test registers a fake first, so the real monitor never probes the
  // internet from a test.
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl.forApi(AppEnv.apiBaseUrl),
    );
  }
  sl.registerLazySingleton<LocaleProvider>(IntlLocaleProvider.new);
  // Refresh goes through a BARE client so it can never re-enter the chain;
  // it still carries the debug trace so the refresh call shows in the log.
  sl.registerLazySingleton<TokenRefresher>(
    () => ApiTokenRefresher(
      Dio(buildApiBaseOptions())..interceptors.addAll([?trace]),
    ),
  );
  // The shared Dio is FULLY configured here (base options + chain), so every
  // consumer — `ApiConsumer` and the SSE client alike — gets the same client
  // no matter which one is resolved first.
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(buildApiBaseOptions());
    dio.interceptors.addAll([
      AuthInterceptor(
        dio: dio,
        session: sl<SessionStore>(),
        refresher: sl<TokenRefresher>(),
        expiry: sl<SessionExpiryNotifier>(),
      ),
      AppHeadersInterceptor(
        locale: sl<LocaleProvider>(),
        session: sl<SessionStore>(),
      ),
      RateLimitRetryInterceptor(dio: dio),
      ReachabilitySignalInterceptor(sl<NetworkInfo>()),
      ?trace,
    ]);
    return dio;
  });
  sl.registerLazySingleton<ApiConsumer>(() => DioConsumer(sl<Dio>()));
  // `text/event-stream` routes (notifications SSE, assistant replies) bypass
  // the envelope; they share the Dio so auth + headers + trace still apply.
  sl.registerLazySingleton<EventStreamClient>(
    () => DioEventStreamClient(sl<Dio>()),
  );
}

Future<void> _initFeatures() async {
  initConnectivityFeature();
  await initCartFeature();
  await initLanguageFeature();
  initStoreModeFeature();
  initHomeFeature();
  initShopFeature();
  initProductDetailsFeature();
  initRecipesFeature();
  initOrdersFeature();
  initAddressFeature();
  initSearchFeature();
  initCheckoutFeature();
  initCouponsFeature();
  initMarketingFeature();
  initAccountFeature();
  initAuthFeature();
  initNotificationsFeature();
  initSupportFeature();
  initAssistantFeature();
}
