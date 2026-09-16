import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/checkout_local_data_source.dart';
import 'data/repositories/checkout_repository_impl.dart';
import 'domain/repositories/checkout_repository.dart';
import 'presentation/cubit/checkout_cubit.dart';

/// Checkout feature DI — mirrors the cart/support templates (offline local
/// chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). The pass-through use cases were collapsed, so the
/// `CheckoutCubit` (`registerFactory`, fresh per screen) now depends on the
/// [CheckoutRepository] directly; repository / datasource are
/// `registerLazySingleton`.
void initCheckoutFeature() {
  if (sl.isRegistered<CheckoutRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<CheckoutLocalDataSource>(
      () => CheckoutLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<CheckoutRepository>(
      () => CheckoutRepositoryImpl(local: sl<CheckoutLocalDataSource>()));

  // Presentation (page-scoped cubit → repository directly)
  sl.registerFactory(
      () => CheckoutCubit(repository: sl<CheckoutRepository>()));
}
