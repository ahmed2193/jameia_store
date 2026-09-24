import '../../config/di/service_locator.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/pro_membership_remote_data_source.dart';
import 'data/repositories/pro_membership_repository_impl.dart';
import 'domain/repositories/pro_membership_repository.dart';
import 'domain/usecases/cancel_pro_subscription_usecase.dart';
import 'domain/usecases/get_pro_program_usecase.dart';
import 'domain/usecases/get_pro_subscription_usecase.dart';
import 'domain/usecases/subscribe_to_pro_usecase.dart';
import 'presentation/cubit/pro_membership_cubit.dart';

/// Store mode DI. The store's pricing "mode" is no longer a local VIP ⇄ Mart
/// toggle over the offline catalogue: the backend sells a **Pro membership**
/// (`GET /v1/subscription-plans`, `/v1/account/subscription`), and member
/// prices apply when `AuthSessionCubit.state.customer.isPro` is true.
/// Called from `setupServiceLocator`.
void initStoreModeFeature() {
  if (sl.isRegistered<ProMembershipRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<ProMembershipRemoteDataSource>(
      () => ProMembershipRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<ProMembershipRepository>(
      () => ProMembershipRepositoryImpl(sl<ProMembershipRemoteDataSource>()),
    )
    ..registerLazySingleton(
      () => GetProProgramUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => GetProSubscriptionUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => SubscribeToProUseCase(sl<ProMembershipRepository>()),
    )
    ..registerLazySingleton(
      () => CancelProSubscriptionUseCase(sl<ProMembershipRepository>()),
    )
    ..registerFactory(
      () => ProMembershipCubit(
        sl<GetProProgramUseCase>(),
        sl<GetProSubscriptionUseCase>(),
        sl<SubscribeToProUseCase>(),
        sl<CancelProSubscriptionUseCase>(),
      ),
    );
}
