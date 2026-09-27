import '../../config/di/service_locator.dart';
import '../../core/network/network_info.dart';
import 'data/datasources/connectivity_data_source.dart';
import 'data/repositories/connectivity_repository_impl.dart';
import 'domain/repositories/connectivity_repository.dart';
import 'domain/usecases/check_connectivity_usecase.dart';
import 'domain/usecases/set_connectivity_monitoring_usecase.dart';
import 'domain/usecases/watch_connectivity_usecase.dart';
import 'presentation/cubit/connectivity_cubit.dart';

/// Connectivity feature DI — the backend reachability monitor ([NetworkInfo],
/// registered by `_initNetwork`) behind the app-global [ConnectivityCubit].
/// Idempotent.
void initConnectivityFeature() {
  if (sl.isRegistered<ConnectivityRepository>()) return; // idempotent
  sl
    // Data
    ..registerLazySingleton<ConnectivityDataSource>(
      () => ConnectivityDataSourceImpl(sl<NetworkInfo>()),
    )
    ..registerLazySingleton<ConnectivityRepository>(
      () => ConnectivityRepositoryImpl(sl<ConnectivityDataSource>()),
    )
    // Domain
    ..registerLazySingleton(() => WatchConnectivityUseCase(sl()))
    ..registerLazySingleton(() => CheckConnectivityUseCase(sl()))
    ..registerLazySingleton(() => SetConnectivityMonitoringUseCase(sl()))
    // Presentation — app-global, created once through `AppGlobalCubits`.
    ..registerFactory(
      () => ConnectivityCubit(watch: sl(), check: sl(), setMonitoring: sl()),
    );
}
