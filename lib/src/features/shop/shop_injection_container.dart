import '../../config/di/service_locator.dart';
import '../../core/data/datasources/catalog_cache_data_source.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/domain/entities/catalog_product_query.dart';
import 'data/repositories/catalog_browse_repository_impl.dart';
import 'domain/repositories/catalog_browse_repository.dart';
import 'domain/usecases/get_listing_category_tabs_usecase.dart';
import 'domain/usecases/get_products_usecase.dart';
import 'domain/usecases/watch_brands_usecase.dart';
import 'domain/usecases/watch_category_tree_usecase.dart';
import 'domain/usecases/watch_products_usecase.dart';
import 'presentation/cubit/brands_cubit.dart';
import 'presentation/cubit/category_browse_cubit.dart';
import 'presentation/cubit/listing_tabs_cubit.dart';
import 'presentation/cubit/product_listing_cubit.dart';

/// Shop feature DI — category browsing + product listings on the jm3eia
/// backend (`GET /v1/categories`, `/v1/products`, `/v1/brands`), their
/// device copies in the shared `CatalogCacheDataSource`.
/// Called from `setupServiceLocator`.
void initShopFeature() {
  if (sl.isRegistered<CatalogBrowseRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<CatalogBrowseRepository>(
      () => CatalogBrowseRepositoryImpl(
        sl<CatalogRemoteDataSource>(),
        cache: sl<CatalogCacheDataSource>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchCategoryTreeUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerLazySingleton(
      () => WatchProductsUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerLazySingleton(
      () => GetProductsUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerLazySingleton(
      () => WatchBrandsUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerLazySingleton(
      () => GetListingCategoryTabsUseCase(sl<CatalogBrowseRepository>()),
    )
    ..registerFactory(() => BrandsCubit(sl<WatchBrandsUseCase>()))
    // param1 = the slug of the category being browsed; '' browses the store.
    ..registerFactoryParam<CategoryBrowseCubit, String, void>(
      (slug, _) =>
          CategoryBrowseCubit(sl<WatchCategoryTreeUseCase>(), baseSlug: slug),
    )
    // param1 = what the list asks the backend for (scope + initial filters).
    ..registerFactoryParam<ProductListingCubit, CatalogProductQuery, void>(
      (query, _) => ProductListingCubit(
        sl<WatchProductsUseCase>(),
        sl<GetProductsUseCase>(),
        sl<WatchBrandsUseCase>(),
        query: query,
      ),
    )
    // param1 = the collection page's list, whose category tabs to find.
    ..registerFactoryParam<ListingTabsCubit, CatalogProductQuery, void>(
      (query, _) =>
          ListingTabsCubit(sl<GetListingCategoryTabsUseCase>(), query: query),
    );
}
