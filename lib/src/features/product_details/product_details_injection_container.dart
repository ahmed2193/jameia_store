import '../../config/di/service_locator.dart';
import '../../config/routes/route_args/product_detail_args.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/product_details_cache_data_source.dart';
import 'data/datasources/product_details_remote_data_source.dart';
import 'data/repositories/product_details_repository_impl.dart';
import 'domain/repositories/product_details_repository.dart';
import 'domain/usecases/get_product_offer_usecase.dart';
import 'domain/usecases/get_product_reviews_usecase.dart';
import 'domain/usecases/watch_product_detail_usecase.dart';
import 'domain/usecases/watch_product_reviews_usecase.dart';
import 'presentation/cubit/product_detail_cubit.dart';
import 'presentation/cubit/product_reviews_cubit.dart';

/// Product page DI — the Hero backend (`GET /v1/products/:slug`,
/// `GET /v1/products/:slug/reviews`, and `GET /v1/offers` through the shared
/// catalogue datasource); the product and its first reviews page are kept on
/// the device. Called from `setupServiceLocator`.
void initProductDetailsFeature() {
  if (sl.isRegistered<ProductDetailsRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<ProductDetailsRemoteDataSource>(
      () => ProductDetailsRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<ProductDetailsCacheDataSource>(
      () => ProductDetailsCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<ProductDetailsRepository>(
      () => ProductDetailsRepositoryImpl(
        sl<ProductDetailsRemoteDataSource>(),
        sl<CatalogRemoteDataSource>(),
        cache: sl<ProductDetailsCacheDataSource>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchProductDetailUseCase(sl<ProductDetailsRepository>()),
    )
    ..registerLazySingleton(
      () => WatchProductReviewsUseCase(sl<ProductDetailsRepository>()),
    )
    ..registerLazySingleton(
      () => GetProductReviewsUseCase(sl<ProductDetailsRepository>()),
    )
    ..registerLazySingleton(
      () => GetProductOfferUseCase(sl<ProductDetailsRepository>()),
    )
    // param1 = the route args (slug + the tapped card as a preview).
    ..registerFactoryParam<ProductDetailCubit, ProductDetailArgs, void>(
      (args, _) => ProductDetailCubit(
        sl<WatchProductDetailUseCase>(),
        sl<GetProductOfferUseCase>(),
        slug: args.slug,
        preview: args.preview,
      ),
    )
    // param1 = the product slug.
    ..registerFactoryParam<ProductReviewsCubit, String, void>(
      (slug, _) => ProductReviewsCubit(
        sl<WatchProductReviewsUseCase>(),
        sl<GetProductReviewsUseCase>(),
        slug: slug,
      ),
    );
}
