import '../../core/config/service_locator.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/lang_local_data_source.dart';
import 'data/repositories/lang_repository_impl.dart';
import 'domain/repositories/lang_repository.dart';
import 'presentation/cubit/localization_cubit.dart';

/// Language feature DI — mirrors khayool's `initLanguageFeature`, adapted to this
/// app's [LocalStorage] (shared_preferences) instead of Hive.
///
/// Registered from `main.dart` (NOT the deny-listed `service_locator.dart`),
/// after `initCoreStorage` has registered the shared [LocalStorage] this feature
/// resolves. Idempotent.
Future<void> initLanguageFeature() async {
  if (sl.isRegistered<LangRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<LangLocalDataSource>(
      () => LangLocalDataSourceImpl(sl<LocalStorage>()));
  sl.registerLazySingleton<LangRepository>(
      () => LangRepositoryImpl(localDataSource: sl<LangLocalDataSource>()));

  // Presentation — factory (fresh per app-root BlocProvider mount).
  // Depends on the repository directly; the former ChangeLangUseCase
  // pass-through was collapsed (P2.9 domain rewrite).
  sl.registerFactory<LocalizationCubit>(
    () => LocalizationCubit(
      repository: sl<LangRepository>(),
    ),
  );
}
