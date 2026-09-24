import '../../config/di/service_locator.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/storage/local_storage.dart';
import 'data/datasources/search_local_data_source.dart';
import 'data/repositories/search_repository_impl.dart';
import 'domain/repositories/search_repository.dart';
import 'domain/usecases/get_recent_searches_usecase.dart';
import 'domain/usecases/get_search_discover_usecase.dart';
import 'domain/usecases/save_recent_searches_usecase.dart';
import 'domain/usecases/suggest_products_usecase.dart';
import 'presentation/cubit/search_cubit.dart';

/// Search feature DI — product matches, categories and brands from the jm3eia
/// backend (the shared `CatalogRemoteDataSource`), recent terms on the device.
/// Called from `setupServiceLocator`.
void initSearchFeature() {
  if (sl.isRegistered<SearchRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<SearchLocalDataSource>(
      () => SearchLocalDataSourceImpl(sl<LocalStorage>()),
    )
    ..registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(
        sl<CatalogRemoteDataSource>(),
        sl<SearchLocalDataSource>(),
      ),
    )
    ..registerLazySingleton(
      () => GetSearchDiscoverUseCase(sl<SearchRepository>()),
    )
    ..registerLazySingleton(
      () => SuggestProductsUseCase(sl<SearchRepository>()),
    )
    ..registerLazySingleton(
      () => GetRecentSearchesUseCase(sl<SearchRepository>()),
    )
    ..registerLazySingleton(
      () => SaveRecentSearchesUseCase(sl<SearchRepository>()),
    )
    ..registerFactory(
      () => SearchCubit(
        sl<GetSearchDiscoverUseCase>(),
        sl<SuggestProductsUseCase>(),
        sl<GetRecentSearchesUseCase>(),
        sl<SaveRecentSearchesUseCase>(),
      ),
    );
}
