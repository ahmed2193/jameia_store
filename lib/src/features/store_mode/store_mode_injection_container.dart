import '../../config/di/service_locator.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/pro_membership_cache_data_source.dart';
import 'data/datasources/pro_membership_remote_data_source.dart';
import 'data/repositories/pro_membership_repository_impl.dart';
import 'domain/repositories/pro_membership_repository.dart';
import 'domain/usecases/cancel_pro_subscription_usecase.dart';
import 'domain/usecases/get_pro_brands_usecase.dart';
import 'domain/usecases/get_pro_membership_usecase.dart';
import 'domain/usecases/get_pro_program_usecase.dart';
import 'domain/usecases/subscribe_to_pro_usecase.dart';
import 'domain/usecases/watch_pro_program_usecase.dart';
import 'domain/usecases/watch_pro_subscription_usecase.dart';
import 'presentation/cubit/pro_brands_cubit.dart';
import 'presentation/cubit/pro_membership_cubit.dart';
import 'presentation/cubit/pro_status_cubit.dart';

/// Store mode DI. The store's pricing "mode" is no longer a local VIP ⇄ Mart
/// toggle over the offline catalogue: the backend sells a **Pro membership**
/// (`GET /v1/subscription-plans`, `/v1/account/subscription`), and member
/// prices apply when `AuthSessionCubit.state.customer.isPro` is true. Where
/// the customer stands with Pro (guest, prospect, renewing, ending, lapsed)
/// is the app-global [ProStatusCubit] every Pro surface reads.
/// Called from `setupServiceLocator`, after `_initCatalog` registered the
/// shared [CatalogRemoteDataSource] (the paywall's brand rows).
void initStoreModeFeature() {
  if (sl.isRegistered<ProMembershipRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<ProMembershipRemoteDataSource>(
      () => ProMembershipRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    // The programme and the customer's subscription as the Pro page last
    // showed them.
    ..registerLazySingleton<ProMembershipCacheDataSource>(
      () => ProMembershipCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<ProMembershipRepository>(
      () => ProMembershipRepositoryImpl(
        sl<ProMembershipRemoteDataSource>(),
        sl<CatalogRemoteDataSource>(),
        cache: sl<ProMembershipCacheDataSource>(),
      ),
    )
    ..registerLazySingleton(
      () => GetProProgramUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => WatchProProgramUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => WatchProSubscriptionUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => SubscribeToProUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => CancelProSubscriptionUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => GetProBrandsUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => GetProMembershipUseCase(sl<ProMembershipRepository>()),
    )
    // App-global: the root provides one (`AppGlobalCubits.proStatus`) and
    // starts / stops it with the session.
    ..registerFactory(
      () => ProStatusCubit(
        sl<GetProMembershipUseCase>(),
        sl<GetProProgramUseCase>(),
      ),
    )
    ..registerFactory(
      () => ProMembershipCubit(
        sl<WatchProProgramUseCase>(),
        sl<WatchProSubscriptionUseCase>(),
        sl<SubscribeToProUseCase>(),
        sl<CancelProSubscriptionUseCase>(),
      ),
    )
    ..registerFactory(() => ProBrandsCubit(sl<GetProBrandsUseCase>()));
}
