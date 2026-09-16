import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/cubit/login_cubit.dart';

/// Auth feature DI — mirrors the support/cart templates (offline local chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). The `LoginCubit` is `registerFactory` (fresh per
/// screen); repository / datasource are `registerLazySingleton`.
void initAuthFeature() {
  if (sl.isRegistered<AuthRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(local: sl<AuthLocalDataSource>()));

  // Presentation (page-scoped cubit) — depends directly on the repository
  // (the pass-through LoginUseCase was collapsed).
  sl.registerFactory(() => LoginCubit(sl<AuthRepository>()));
}
