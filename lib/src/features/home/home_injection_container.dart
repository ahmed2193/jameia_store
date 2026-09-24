import '../../config/di/service_locator.dart';
import '../../core/network/api_consumer.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/home_local_data_source.dart';
import 'data/datasources/home_remote_data_source.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';
import 'domain/usecases/compose_home_feed_usecase.dart';
import 'domain/usecases/get_home_bootstrap_usecase.dart';
import 'domain/usecases/get_home_feed_usecase.dart';
import 'domain/usecases/mark_home_popups_shown_usecase.dart';
import 'domain/usecases/select_due_home_popups_usecase.dart';
import 'presentation/cubit/home_cubit.dart';

/// Home feature DI — the jm3eia backend (`GET /v1/home`, `GET /v1/init`) plus
/// local popup stamps. Called from `setupServiceLocator`.
void initHomeFeature() {
  if (sl.isRegistered<HomeRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(sl<LocalStorage>()),
    )
    ..registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        sl<HomeRemoteDataSource>(),
        sl<HomeLocalDataSource>(),
      ),
    )
    ..registerLazySingleton(() => GetHomeFeedUseCase(sl<HomeRepository>()))
    ..registerLazySingleton(ComposeHomeFeedUseCase.new)
    ..registerLazySingleton(() => GetHomeBootstrapUseCase(sl<HomeRepository>()))
    ..registerLazySingleton(
      () => SelectDueHomePopupsUseCase(sl<HomeRepository>()),
    )
    ..registerLazySingleton(
      () => MarkHomePopupsShownUseCase(sl<HomeRepository>()),
    )
    ..registerFactory(
      () => HomeCubit(
        sl<GetHomeFeedUseCase>(),
        sl<ComposeHomeFeedUseCase>(),
        sl<GetHomeBootstrapUseCase>(),
        sl<SelectDueHomePopupsUseCase>(),
        sl<MarkHomePopupsShownUseCase>(),
      ),
    );
}
