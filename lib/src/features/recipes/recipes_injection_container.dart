import '../../config/di/service_locator.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/recipes_cache_data_source.dart';
import 'data/datasources/recipes_remote_data_source.dart';
import 'data/repositories/recipes_repository_impl.dart';
import 'domain/repositories/recipes_repository.dart';
import 'domain/usecases/get_recipes_usecase.dart';
import 'domain/usecases/watch_recipe_detail_usecase.dart';
import 'domain/usecases/watch_recipes_usecase.dart';
import 'presentation/cubit/recipe_detail_cubit.dart';
import 'presentation/cubit/recipes_cubit.dart';

/// Recipes feature DI — the jm3eia backend (`GET /v1/recipes`,
/// `GET /v1/recipes/:slug`), the first page and each recipe kept on the
/// device. Called from `setupServiceLocator`.
void initRecipesFeature() {
  if (sl.isRegistered<RecipesRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<RecipesRemoteDataSource>(
      () => RecipesRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<RecipesCacheDataSource>(
      () => RecipesCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<RecipesRepository>(
      () => RecipesRepositoryImpl(
        sl<RecipesRemoteDataSource>(),
        cache: sl<RecipesCacheDataSource>(),
      ),
    )
    ..registerLazySingleton(() => WatchRecipesUseCase(sl<RecipesRepository>()))
    ..registerLazySingleton(() => GetRecipesUseCase(sl<RecipesRepository>()))
    ..registerLazySingleton(
      () => WatchRecipeDetailUseCase(sl<RecipesRepository>()),
    )
    ..registerFactory(
      () => RecipesCubit(sl<WatchRecipesUseCase>(), sl<GetRecipesUseCase>()),
    )
    // param1 = the recipe slug.
    ..registerFactoryParam<RecipeDetailCubit, String, void>(
      (slug, _) =>
          RecipeDetailCubit(sl<WatchRecipeDetailUseCase>(), slug: slug),
    );
}
