import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/account_local_data_source.dart';
import 'data/repositories/account_repository_impl.dart';
import 'domain/repositories/account_repository.dart';
import 'presentation/cubit/account_cubit.dart';
import 'presentation/cubit/delivery_code_cubit.dart';

/// Account feature DI — mirrors the support/cart templates (offline local chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). Cubits are `registerFactory` (fresh per screen);
/// use cases / repository / datasource are `registerLazySingleton`.
///
/// `SettingCubit` is intentionally NOT registered here: it is an app-root
/// settings orchestrator provided in `main.dart`, not a data-reading page cubit.
void initAccountFeature() {
  if (sl.isRegistered<AccountRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<AccountLocalDataSource>(
      () => AccountLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(local: sl<AccountLocalDataSource>()));

  // Presentation (page-scoped cubits) — the two pass-through use cases were
  // collapsed; cubits now read the repository directly.
  sl.registerFactory(() => AccountCubit(sl<AccountRepository>()));
  sl.registerFactory(() => DeliveryCodeCubit(sl<AccountRepository>()));
}
