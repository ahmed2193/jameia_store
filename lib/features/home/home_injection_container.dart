import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/home_local_data_source.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';
import 'domain/usecases/select_home_filter_usecase.dart';
import 'presentation/cubit/home_cubit.dart';

/// Home feature DI — mirrors the cart/support templates (offline local chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). The page cubit is `registerFactory` (fresh per
/// screen); use cases / repository / datasource are `registerLazySingleton`.
void initHomeFeature() {
  if (sl.isRegistered<HomeRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(local: sl<HomeLocalDataSource>()));

  // Domain (use cases) — the pass-through GetHomeFeedUseCase was collapsed; the
  // cubit now reads the repository directly.
  sl.registerLazySingleton(() => const SelectHomeFilterUseCase());

  // Presentation (page-scoped cubit)
  sl.registerFactory(
      () => HomeCubit(sl<HomeRepository>(), sl<SelectHomeFilterUseCase>()));
}
