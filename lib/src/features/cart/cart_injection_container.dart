import '../../config/di/service_locator.dart';
import '../../core/data/jameia_repository.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/cart_local_data_source.dart';
import 'data/repositories/cart_repository_impl.dart';
import 'domain/repositories/cart_repository.dart';
import 'presentation/cubit/cart_cubit.dart';

/// Cart feature DI (offline datasource). Called from `setupServiceLocator`.
Future<void> initCartFeature() async {
  if (sl.isRegistered<CartRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(sl<LocalStorage>()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      local: sl<CartLocalDataSource>(),
      catalog: sl<JameiaRepository>(),
    ),
  );

  // Presentation — app-root cubit, fresh per BlocProvider mount.
  sl.registerFactory<CartCubit>(
    () => CartCubit.inject(repository: sl<CartRepository>()),
  );
}
