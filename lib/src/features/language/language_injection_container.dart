import '../../config/di/service_locator.dart';
import '../../core/network/api_consumer.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/session_store.dart';
import 'data/datasources/lang_local_data_source.dart';
import 'data/datasources/lang_remote_data_source.dart';
import 'data/repositories/lang_repository_impl.dart';
import 'domain/repositories/lang_repository.dart';
import 'domain/usecases/change_lang_usecase.dart';
import 'domain/usecases/get_saved_lang_usecase.dart';
import 'domain/usecases/sync_language_usecase.dart';
import 'presentation/cubit/localization_cubit.dart';

/// Language feature DI — local persistence on the shared [LocalStorage]
/// (shared_preferences) plus the account mirror over the core `ApiConsumer`.
///
/// Runs after `initCoreStorage` / `_initSession` / `_initNetwork` have
/// registered [LocalStorage], [SessionStore] and [ApiConsumer]. Idempotent.
Future<void> initLanguageFeature() async {
  if (sl.isRegistered<LangRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<LangLocalDataSource>(
      () => LangLocalDataSourceImpl(sl<LocalStorage>(), sl<SessionStore>()),
    )
    ..registerLazySingleton<LangRemoteDataSource>(
      () => LangRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<LangRepository>(
      () => LangRepositoryImpl(local: sl(), remote: sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetSavedLangUseCase(sl()))
    ..registerLazySingleton(() => ChangeLangUseCase(sl()))
    ..registerLazySingleton(() => SyncLanguageUseCase(sl()))
    // Presentation — factory (fresh per app-root BlocProvider mount).
    ..registerFactory<LocalizationCubit>(
      () => LocalizationCubit(
        getSavedLang: sl(),
        changeLang: sl(),
        syncLanguage: sl(),
      ),
    );
}
