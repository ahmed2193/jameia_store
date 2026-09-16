import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/discovery_local_data_source.dart';
import 'data/repositories/discovery_repository_impl.dart';
import 'domain/repositories/discovery_repository.dart';
import 'domain/usecases/get_channel_list_usecase.dart';
import 'domain/usecases/get_fixed_price_usecase.dart';
import 'domain/usecases/get_kingkong_landing_usecase.dart';
import 'domain/usecases/get_meal_for_one_usecase.dart';
import 'domain/usecases/get_pick_up_shops_usecase.dart';
import 'presentation/cubit/channel_list_cubit.dart';
import 'presentation/cubit/fixed_price_cubit.dart';
import 'presentation/cubit/kingkong_landing_cubit.dart';
import 'presentation/cubit/meal_for_one_cubit.dart';
import 'presentation/cubit/pick_up_cubit.dart';

/// Discovery feature DI — mirrors the cart/support templates (offline local
/// chain). Called from `main.dart` after [setupServiceLocator] (which registers
/// the loaded [KeetaRepository]). Cubits are `registerFactory` (fresh per
/// screen); use cases / repository / datasource are `registerLazySingleton`.
void initDiscoveryFeature() {
  if (sl.isRegistered<DiscoveryRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<DiscoveryLocalDataSource>(
    () => DiscoveryLocalDataSourceImpl(sl<KeetaRepository>()),
  );
  sl.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepositoryImpl(local: sl<DiscoveryLocalDataSource>()),
  );

  // Domain (use cases)
  sl.registerLazySingleton(() => GetChannelListUseCase(sl<DiscoveryRepository>()));
  sl.registerLazySingleton(
    () => GetKingKongLandingUseCase(sl<DiscoveryRepository>()),
  );
  sl.registerLazySingleton(
    () => GetPickUpShopsUseCase(sl<DiscoveryRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMealForOneUseCase(sl<DiscoveryRepository>()),
  );
  sl.registerLazySingleton(() => GetFixedPriceUseCase(sl<DiscoveryRepository>()));

  // Presentation (page-scoped cubits)
  sl.registerFactory(() => ChannelListCubit(sl<GetChannelListUseCase>()));
  sl.registerFactory(
    () => KingKongLandingCubit(sl<GetKingKongLandingUseCase>()),
  );
  sl.registerFactory(() => PickUpCubit(sl<GetPickUpShopsUseCase>()));
  sl.registerFactory(() => MealForOneCubit(sl<GetMealForOneUseCase>()));
  sl.registerFactory(() => FixedPriceCubit(sl<GetFixedPriceUseCase>()));
}
