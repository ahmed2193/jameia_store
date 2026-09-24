import '../../config/di/service_locator.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/promotions_remote_data_source.dart';
import 'data/repositories/promotions_repository_impl.dart';
import 'domain/entities/content_page_entity.dart';
import 'domain/repositories/promotions_repository.dart';
import 'domain/usecases/get_content_page_usecase.dart';
import 'domain/usecases/get_offers_usecase.dart';
import 'presentation/cubit/content_page_cubit.dart';
import 'presentation/cubit/offers_cubit.dart';

/// Marketing feature DI — the jm3eia backend's offers (`GET /v1/offers`) and
/// CMS pages (`GET /v1/pages/:slug`). Called from `setupServiceLocator`.
void initMarketingFeature() {
  if (sl.isRegistered<PromotionsRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<PromotionsRemoteDataSource>(
      () => PromotionsRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<PromotionsRepository>(
      () => PromotionsRepositoryImpl(sl<PromotionsRemoteDataSource>()),
    )
    ..registerLazySingleton(() => GetOffersUseCase(sl<PromotionsRepository>()))
    ..registerLazySingleton(
      () => GetContentPageUseCase(sl<PromotionsRepository>()),
    )
    ..registerFactory(() => OffersCubit(sl<GetOffersUseCase>()))
    // param1 = which CMS page.
    ..registerFactoryParam<ContentPageCubit, ContentPageKind, void>(
      (kind, _) => ContentPageCubit(sl<GetContentPageUseCase>(), kind: kind),
    );
}
