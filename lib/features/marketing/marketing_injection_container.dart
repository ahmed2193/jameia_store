import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/marketing_local_data_source.dart';
import 'data/repositories/marketing_repository_impl.dart';
import 'domain/repositories/marketing_repository.dart';
import 'presentation/cubit/invite_friends_cubit.dart';
import 'presentation/cubit/punctual_cubit.dart';

/// Marketing feature DI — mirrors the cart/support template (offline local
/// chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). Cubits are `registerFactory` (fresh per screen);
/// repository / datasource are `registerLazySingleton`. The pass-through use
/// cases were collapsed — cubits depend on the [MarketingRepository] directly.
void initMarketingFeature() {
  if (sl.isRegistered<MarketingRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<MarketingLocalDataSource>(
      () => MarketingLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<MarketingRepository>(
      () => MarketingRepositoryImpl(local: sl<MarketingLocalDataSource>()));

  // Presentation (page-scoped cubits) — pass-through use cases collapsed; the
  // cubits call the [MarketingRepository] directly.
  sl.registerFactory(() => PunctualCubit(sl<MarketingRepository>()));
  sl.registerFactory(() => InviteFriendsCubit(sl<MarketingRepository>()));
}
