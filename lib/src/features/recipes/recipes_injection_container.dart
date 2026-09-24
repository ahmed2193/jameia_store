import '../../config/di/service_locator.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/recipes_remote_data_source.dart';
import 'data/repositories/recipes_repository_impl.dart';
import 'domain/repositories/recipes_repository.dart';
import 'domain/usecases/get_recipe_detail_usecase.dart';
import 'domain/usecases/get_recipes_usecase.dart';
import 'presentation/cubit/recipe_detail_cubit.dart';
import 'presentation/cubit/recipes_cubit.dart';

/// Recipes feature DI — the jm3eia backend (`GET /v1/recipes`,
/// `GET /v1/recipes/:slug`). Called from `setupServiceLocator`.
void initRecipesFeature() {
  if (sl.isRegistered<RecipesRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<RecipesRemoteDataSource>(
      () => RecipesRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<RecipesRepository>(
      () => RecipesRepositoryImpl(sl<RecipesRemoteDataSource>()),
    )
    ..registerLazySingleton(() => GetRecipesUseCase(sl<RecipesRepository>()))
    ..registerLazySingleton(
      () => GetRecipeDetailUseCase(sl<RecipesRepository>()),
    )
    ..registerFactory(() => RecipesCubit(sl<GetRecipesUseCase>()))
    // param1 = the recipe slug.
    ..registerFactoryParam<RecipeDetailCubit, String, void>(
      (slug, _) => RecipeDetailCubit(sl<GetRecipeDetailUseCase>(), slug: slug),
    );
}
