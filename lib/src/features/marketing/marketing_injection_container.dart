import '../../config/di/service_locator.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/data/datasources/catalog_cache_data_source.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/promotions_cache_data_source.dart';
import 'data/datasources/promotions_remote_data_source.dart';
import 'data/repositories/promotions_repository_impl.dart';
import 'domain/entities/content_page_entity.dart';
import 'domain/repositories/promotions_repository.dart';
import 'domain/usecases/watch_content_page_usecase.dart';
import 'domain/usecases/watch_offers_usecase.dart';
import 'presentation/cubit/content_page_cubit.dart';
import 'presentation/cubit/offers_cubit.dart';

/// Marketing feature DI — the Hero backend's offers (`GET /v1/offers`,
/// through the shared catalogue datasource and its device copy) and CMS
/// pages (`GET /v1/pages/:slug`, kept on the device). Called from
/// `setupServiceLocator`.
void initMarketingFeature() {
  if (sl.isRegistered<PromotionsRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<PromotionsRemoteDataSource>(
      () => PromotionsRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<PromotionsCacheDataSource>(
      () => PromotionsCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<PromotionsRepository>(
      () => PromotionsRepositoryImpl(
        sl<PromotionsRemoteDataSource>(),
        sl<CatalogRemoteDataSource>(),
        cache: sl<PromotionsCacheDataSource>(),
        catalogCache: sl<CatalogCacheDataSource>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchOffersUseCase(sl<PromotionsRepository>()),
    )
    ..registerLazySingleton(
      () => WatchContentPageUseCase(sl<PromotionsRepository>()),
    )
    ..registerFactory(() => OffersCubit(sl<WatchOffersUseCase>()))
    // param1 = which CMS page.
    ..registerFactoryParam<ContentPageCubit, ContentPageKind, void>(
      (kind, _) => ContentPageCubit(sl<WatchContentPageUseCase>(), kind: kind),
    );
}
