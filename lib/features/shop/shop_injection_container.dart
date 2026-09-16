import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/shop_local_data_source.dart';
import 'data/repositories/shop_repository_impl.dart';
import 'domain/repositories/shop_repository.dart';
import 'presentation/cubit/shop_detail_cubit.dart';
import 'presentation/cubit/shop_favorites_cubit.dart';

/// Shop feature DI — mirrors the cart/support templates (offline local chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). Cubits are `registerFactory` (fresh per screen);
/// the repository / datasource are `registerLazySingleton`.
///
/// The two pass-through use cases (`GetShopDetailUseCase`,
/// `GetFavoriteShopsUseCase`) were collapsed — the page cubits now depend on the
/// [ShopRepository] directly. The UI-coordination cubits (`ShopMenuCubit`,
/// `ShopSkuCubit`) are constructed inline with their runtime args (tab index /
/// product), so they are NOT service-locator entries.
void initShopFeature() {
  if (sl.isRegistered<ShopRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<ShopLocalDataSource>(
      () => ShopLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<ShopRepository>(
      () => ShopRepositoryImpl(local: sl<ShopLocalDataSource>()));

  // Presentation (page-scoped cubits) — depend on the repository directly.
  sl.registerFactory(() => ShopDetailCubit(sl<ShopRepository>()));
  sl.registerFactory(() => ShopFavoritesCubit(sl<ShopRepository>()));
}
