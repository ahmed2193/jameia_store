import '../../config/di/service_locator.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/network/api_consumer.dart';
import '../../core/network/locale_provider.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/home_cache_data_source.dart';
import 'data/datasources/home_local_data_source.dart';
import 'data/datasources/home_remote_data_source.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';
import 'domain/usecases/check_first_order_welcome_usecase.dart';
import 'domain/usecases/compose_home_feed_usecase.dart';
import 'domain/usecases/mark_home_popups_shown_usecase.dart';
import 'domain/usecases/select_due_home_popups_usecase.dart';
import 'domain/usecases/watch_home_bootstrap_usecase.dart';
import 'domain/usecases/watch_home_feed_usecase.dart';
import 'presentation/cubit/first_order_bar_cubit.dart';
import 'presentation/cubit/home_cubit.dart';
import 'presentation/cubit/home_launch_prefetch.dart';

/// Home feature DI — the Hero backend (`GET /v1/home`, `GET /v1/init` and
/// their saved copies — the offline cache; the customer's order count for the
/// first-order welcome gift) and local popup stamps. Called from
/// `setupServiceLocator`.
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
    ..registerLazySingleton(
      () => CheckFirstOrderWelcomeUseCase(sl<HomeRepository>()),
    )
    // Home's first read, started by the splash (B1-14) once the saved
    // language is restored: the home page's cubit is the one already
    // reading, once, when it was read in the language that is on now;
    // later ones are fresh. Either way it comes out loading (or loaded).
    ..registerLazySingleton(
      () => HomeLaunchPrefetch(
        () => HomeCubit(
          sl<WatchHomeFeedUseCase>(),
          sl<ComposeHomeFeedUseCase>(),
          sl<WatchHomeBootstrapUseCase>(),
          sl<SelectDueHomePopupsUseCase>(),
          sl<MarkHomePopupsShownUseCase>(),
          sl<CheckFirstOrderWelcomeUseCase>(),
        ),
        language: () => sl<LocaleProvider>().languageCode,
      ),
    )
    ..registerFactory<HomeCubit>(() => sl<HomeLaunchPrefetch>().adopt())
    // The first-order bar on the shell's tab bar, fed by the home tab.
    ..registerFactory(FirstOrderBarCubit.new);
}
