import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/repositories/store_mode_repository_impl.dart';
import 'domain/repositories/store_mode_repository.dart';
import 'presentation/cubit/store_mode_cubit.dart';

/// Store-mode feature DI. Called from `main.dart` after [setupServiceLocator]
/// (which registers the loaded [KeetaRepository]). The cubit is `registerFactory`
/// but provided ONCE at the app root (see `main.dart`), so it behaves as the
/// single global store-mode source of truth.
void initStoreModeFeature() {
  if (sl.isRegistered<StoreModeRepository>()) return; // idempotent

  sl.registerLazySingleton<StoreModeRepository>(
      () => StoreModeRepositoryImpl(sl<KeetaRepository>()));

  sl.registerFactory(() => StoreModeCubit(sl<StoreModeRepository>()));
}
