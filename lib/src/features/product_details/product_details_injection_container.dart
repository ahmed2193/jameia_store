import '../../config/di/service_locator.dart';
import '../../config/routes/route_args/product_detail_args.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/product_details_remote_data_source.dart';
import 'data/repositories/product_details_repository_impl.dart';
import 'domain/repositories/product_details_repository.dart';
import 'domain/usecases/get_product_detail_usecase.dart';
import 'domain/usecases/get_product_reviews_usecase.dart';
import 'presentation/cubit/product_detail_cubit.dart';
import 'presentation/cubit/product_reviews_cubit.dart';

/// Product page DI — the jm3eia backend (`GET /v1/products/:slug`,
/// `GET /v1/products/:slug/reviews`). Called from `setupServiceLocator`.
void initProductDetailsFeature() {
  if (sl.isRegistered<ProductDetailsRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<ProductDetailsRemoteDataSource>(
      () => ProductDetailsRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<ProductDetailsRepository>(
      () => ProductDetailsRepositoryImpl(sl<ProductDetailsRemoteDataSource>()),
    )
    ..registerLazySingleton(
      () => GetProductDetailUseCase(sl<ProductDetailsRepository>()),
    )
    ..registerLazySingleton(
      () => GetProductReviewsUseCase(sl<ProductDetailsRepository>()),
    )
    // param1 = the route args (slug + the tapped card as a preview).
    ..registerFactoryParam<ProductDetailCubit, ProductDetailArgs, void>(
      (args, _) => ProductDetailCubit(
        sl<GetProductDetailUseCase>(),
        slug: args.slug,
        preview: args.preview,
      ),
    )
    // param1 = the product slug.
    ..registerFactoryParam<ProductReviewsCubit, String, void>(
      (slug, _) =>
          ProductReviewsCubit(sl<GetProductReviewsUseCase>(), slug: slug),
    );
}
