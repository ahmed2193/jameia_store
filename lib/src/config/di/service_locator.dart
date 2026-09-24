import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/data/jameia_repository.dart';
import '../../core/network/api_base_options.dart';
import '../../core/network/api_consumer.dart';
import '../../core/network/dio_consumer.dart';
import '../../core/network/event_stream_client.dart';
import '../../core/network/interceptors/app_headers_interceptor.dart';
import '../../core/network/interceptors/auth_interceptor.dart';
import '../../core/network/interceptors/network_log_interceptor.dart';
import '../../core/network/interceptors/rate_limit_retry_interceptor.dart';
import '../../core/network/locale_provider.dart';
import '../../core/network/network_info.dart';
import '../../core/network/session_expiry_notifier.dart';
import '../../core/network/token_refresher.dart';
import '../../core/storage/session_store.dart';
import '../../core/storage/storage_injection.dart';
import '../../features/account/account_injection_container.dart';
import '../../features/address/address_injection_container.dart';
import '../../features/auth/auth_injection_container.dart';
import '../../features/cart/cart_injection_container.dart';
import '../../features/checkout/checkout_injection_container.dart';
import '../../features/coupons/coupons_injection_container.dart';
import '../../features/discovery/discovery_injection_container.dart';
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
  if (!sl.isRegistered<JameiaRepository>()) {
    final repo = JameiaRepository();
    await repo.load();
    sl.registerSingleton<JameiaRepository>(repo);
  }

  // Shared LocalStorage / SharedPreferences.
  await initCoreStorage();

  _initSession();
  _initNetwork();
  _initCatalog();
}

/// Catalogue reads shared by several features (product list, category tree,
/// brand list) — see [CatalogRemoteDataSource].
void _initCatalog() {
  if (sl.isRegistered<CatalogRemoteDataSource>()) return;
  sl.registerLazySingleton<CatalogRemoteDataSource>(
    () => CatalogRemoteDataSourceImpl(sl<ApiConsumer>(), sl<LocaleProvider>()),
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
/// → app headers (language / guest identities) → 429 backoff → debug trace.
void _initNetwork() {
  if (sl.isRegistered<ApiConsumer>()) return;
  // One trace for every client so request numbers stay in one sequence.
  final NetworkLogInterceptor? trace = kDebugMode
      ? NetworkLogInterceptor()
      : null;
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(InternetConnection()),
  );
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
  initDiscoveryFeature();
  initMarketingFeature();
  initAccountFeature();
  initAuthFeature();
  initNotificationsFeature();
  initSupportFeature();
}
