import '../../config/di/service_locator.dart';
import '../../core/data/jameia_repository.dart';
import '../../core/domain/entities/auth_customer_entity.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/account_local_data_source.dart';
import 'data/datasources/account_remote_data_source.dart';
import 'data/repositories/account_repository_impl.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/usecases/get_account_overview_usecase.dart';
import 'domain/usecases/get_delivery_code_usecase.dart';
import 'domain/usecases/get_profile_usecase.dart';
import 'domain/usecases/update_profile_usecase.dart';
import 'presentation/cubit/account_cubit.dart';
import 'presentation/cubit/delivery_code_cubit.dart';
import 'presentation/cubit/profile_cubit.dart';

/// Account feature DI — offline overview / delivery code + the live profile
/// (`GET /v1/account/me`, `PATCH /v1/account/profile`) over the core
/// `ApiConsumer`. Cubits are `registerFactory` (fresh per screen).
///
/// `SettingCubit` is intentionally NOT registered here: it is an app-root
/// settings orchestrator provided in `app.dart`, not a data-reading page cubit.
void initAccountFeature() {
  if (sl.isRegistered<AccountRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<AccountLocalDataSource>(
      () => AccountLocalDataSourceImpl(sl<JameiaRepository>()),
    )
    ..registerLazySingleton<AccountRemoteDataSource>(
      () => AccountRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(remote: sl(), local: sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetAccountOverviewUseCase(sl()))
    ..registerLazySingleton(() => GetDeliveryCodeUseCase(sl()))
    ..registerLazySingleton(() => GetProfileUseCase(sl()))
    ..registerLazySingleton(() => UpdateProfileUseCase(sl()))
    // Presentation — the profile cubit takes the customer the app already
    // knows (from the session) so the form renders before the refresh lands.
    ..registerFactory(() => AccountCubit(sl()))
    ..registerFactory(() => DeliveryCodeCubit(sl()))
    ..registerFactoryParam<ProfileCubit, AuthCustomerEntity?, void>(
      (initial, _) =>
          ProfileCubit(getProfile: sl(), updateProfile: sl(), initial: initial),
    );
}
