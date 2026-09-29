import '../../config/di/service_locator.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/network/api_consumer.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/home_cache_data_source.dart';
import 'data/datasources/home_local_data_source.dart';
import 'data/datasources/home_remote_data_source.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';
import 'domain/usecases/compose_home_feed_usecase.dart';
import 'domain/usecases/mark_home_popups_shown_usecase.dart';
import 'domain/usecases/select_due_home_popups_usecase.dart';
import 'domain/usecases/watch_home_bootstrap_usecase.dart';
import 'domain/usecases/watch_home_feed_usecase.dart';
import 'presentation/cubit/home_cubit.dart';
import 'presentation/cubit/home_launch_prefetch.dart';

/// Home feature DI — the Hero backend (`GET /v1/home`, `GET /v1/init`),
/// their saved copies (the offline cache), and local popup stamps. Called
/// from `setupServiceLocator`.
void initHomeFeature() {
  if (sl.isRegistered<HomeRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(sl<LocalStorage>()),
    )
    ..registerLazySingleton<HomeCacheDataSource>(
      () => HomeCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        sl<HomeRemoteDataSource>(),
        sl<HomeLocalDataSource>(),
        cache: sl<HomeCacheDataSource>(),
      ),
    )
    ..registerLazySingleton(() => WatchHomeFeedUseCase(sl<HomeRepository>()))
    ..registerLazySingleton(ComposeHomeFeedUseCase.new)
    ..registerLazySingleton(
      () => WatchHomeBootstrapUseCase(sl<HomeRepository>()),
    )
    ..registerLazySingleton(
      () => SelectDueHomePopupsUseCase(sl<HomeRepository>()),
    )
    ..registerLazySingleton(
      () => MarkHomePopupsShownUseCase(sl<HomeRepository>()),
    )
    // Home's first read, started by the splash (B1-14): the home page's
    // cubit is the one already reading, once; later ones are fresh. Either
    // way it comes out loading (or loaded).
    ..registerLazySingleton(
      () => HomeLaunchPrefetch(
        () => HomeCubit(
          sl<WatchHomeFeedUseCase>(),
          sl<ComposeHomeFeedUseCase>(),
          sl<WatchHomeBootstrapUseCase>(),
          sl<SelectDueHomePopupsUseCase>(),
          sl<MarkHomePopupsShownUseCase>(),
        ),
      ),
    )
    ..registerFactory<HomeCubit>(() => sl<HomeLaunchPrefetch>().adopt());
}
