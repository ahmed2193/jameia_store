import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/cart_local_data_source.dart';
import 'data/repositories/cart_repository_impl.dart';
import 'domain/repositories/cart_repository.dart';

/// Cart feature DI — mirrors Ttapasco's `initNewCartFeature` (offline datasource).
///
/// Called from `main.dart` **after** [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). Registrations live here — not in the protected
/// `service_locator.dart` — so the cart rehydrate can read the loaded catalogue.
/// The `CartCubit` itself is registered by `service_locator.dart`'s existing
/// `registerFactory<CartCubit>`; its no-arg factory resolves the [CartRepository]
/// wired below (the five pass-through use cases were collapsed into direct
/// repository calls on the cubit).
Future<void> initCartFeature() async {
  if (sl.isRegistered<CartRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(sl<LocalStorage>()));
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(
        local: sl<CartLocalDataSource>(),
        catalog: sl<KeetaRepository>(),
      ));
}
