import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/search_local_data_source.dart';
import 'data/repositories/search_repository_impl.dart';
import 'domain/repositories/search_repository.dart';
import 'domain/usecases/search_usecase.dart';
import 'presentation/cubit/search_cubit.dart';

/// Search feature DI — mirrors the cart/support templates (offline local chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]) and after `initCoreStorage` (which registers the
/// shared [LocalStorage] singleton the recents datasource resolves lazily).
/// [SearchCubit] is `registerFactory` (fresh per screen — the discover screen
/// and the results screen each provide their own instance); the kept use case /
/// repository / datasource are `registerLazySingleton`. The five former
/// pass-through use cases (hot words / recents / suggestions) were collapsed —
/// the cubit now calls [SearchRepository] directly.
void initSearchFeature() {
  if (sl.isRegistered<SearchRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<SearchLocalDataSource>(
      () => SearchLocalDataSourceImpl(sl<KeetaRepository>(), sl<LocalStorage>()));
  sl.registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(local: sl<SearchLocalDataSource>()));

  // Domain (with-logic use case only)
  sl.registerLazySingleton(() => SearchUseCase(sl<SearchRepository>()));

  // Presentation (page-scoped cubit — one instance per screen)
  sl.registerFactory(() => SearchCubit(
        search: sl<SearchUseCase>(),
        repository: sl<SearchRepository>(),
      ));
}
