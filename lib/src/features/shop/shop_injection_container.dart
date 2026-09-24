import '../../config/di/service_locator.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/domain/entities/catalog_product_query.dart';
import 'data/repositories/catalog_browse_repository_impl.dart';
import 'domain/repositories/catalog_browse_repository.dart';
import 'domain/usecases/get_brands_usecase.dart';
import 'domain/usecases/get_category_tree_usecase.dart';
import 'domain/usecases/get_products_usecase.dart';
import 'presentation/cubit/brands_cubit.dart';
import 'presentation/cubit/category_browse_cubit.dart';
import 'presentation/cubit/product_listing_cubit.dart';

/// Shop feature DI — category browsing + product listings on the jm3eia
/// backend (`GET /v1/categories`, `/v1/products`, `/v1/brands`).
/// Called from `setupServiceLocator`.
void initShopFeature() {
  if (sl.isRegistered<CatalogBrowseRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<CatalogBrowseRepository>(
      () => CatalogBrowseRepositoryImpl(sl<CatalogRemoteDataSource>()),
    )
    ..registerLazySingleton(
      () => GetCategoryTreeUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerLazySingleton(
      () => GetProductsUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerLazySingleton(
      () => GetBrandsUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerFactory(() => BrandsCubit(sl<GetBrandsUseCase>()))
    // param1 = the slug of the category being browsed; '' browses the store.
    ..registerFactoryParam<CategoryBrowseCubit, String, void>(
      (slug, _) =>
          CategoryBrowseCubit(sl<GetCategoryTreeUseCase>(), baseSlug: slug),
    )
    // param1 = what the list asks the backend for (scope + initial filters).
    ..registerFactoryParam<ProductListingCubit, CatalogProductQuery, void>(
      (query, _) => ProductListingCubit(
        sl<GetProductsUseCase>(),
        sl<GetBrandsUseCase>(),
        query: query,
      ),
    );
}
