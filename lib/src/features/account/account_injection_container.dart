import '../../config/di/service_locator.dart';
import '../../core/data/datasources/cache_slots.dart';
import '../../core/data/jameia_repository.dart';
import '../../core/domain/entities/auth_customer_entity.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/account_local_data_source.dart';
import 'data/datasources/account_remote_data_source.dart';
import 'data/datasources/ledger_cache_data_source.dart';
import 'data/datasources/loyalty_remote_data_source.dart';
import 'data/datasources/wallet_remote_data_source.dart';
import 'data/repositories/account_repository_impl.dart';
import 'data/repositories/loyalty_repository_impl.dart';
import 'data/repositories/wallet_repository_impl.dart';
import 'domain/entities/loyalty_entry_entity.dart';
import 'domain/entities/wallet_entry_entity.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/repositories/loyalty_repository.dart';
import 'domain/repositories/wallet_repository.dart';
import 'domain/usecases/get_account_overview_usecase.dart';
import 'domain/usecases/get_delivery_code_usecase.dart';
import 'domain/usecases/get_loyalty_ledger_usecase.dart';
import 'domain/usecases/get_loyalty_program_usecase.dart';
import 'domain/usecases/get_loyalty_rewards_usecase.dart';
import 'domain/usecases/get_profile_usecase.dart';
import 'domain/usecases/get_wallet_ledger_usecase.dart';
import 'domain/usecases/update_profile_usecase.dart';
import 'domain/usecases/watch_loyalty_ledger_usecase.dart';
import 'domain/usecases/watch_wallet_ledger_usecase.dart';
import 'presentation/cubit/account_cubit.dart';
import 'presentation/cubit/delivery_code_cubit.dart';
import 'presentation/cubit/ledger_cubit.dart';
import 'presentation/cubit/loyalty_program_cubit.dart';
import 'presentation/cubit/loyalty_rewards_cubit.dart';
import 'presentation/cubit/profile_cubit.dart';

/// Account feature DI — offline overview / delivery code, the live profile
/// (`GET /v1/account/me`, `PATCH /v1/account/profile`), the wallet
/// (`GET /v1/account/wallet`) and the loyalty points (`GET
/// /v1/account/loyalty` + the programme from `GET /v1/init`) over the core
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
    ..registerLazySingleton<WalletRemoteDataSource>(
      () => WalletRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    // One instance for the run: it keeps the loyalty programme once loaded.
    ..registerLazySingleton<LoyaltyRemoteDataSource>(
      () => LoyaltyRemoteDataSourceImpl(sl<ApiConsumer>()),
    )
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(remote: sl(), local: sl()),
    )
    // The wallet / points histories' first pages, kept on the device for
    // the signed-in customer.
    ..registerLazySingleton<LedgerCacheDataSource>(
      () => LedgerCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(sl(), cache: sl()),
    )
    ..registerLazySingleton<LoyaltyRepository>(
      () => LoyaltyRepositoryImpl(sl(), cache: sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetAccountOverviewUseCase(sl()))
    ..registerLazySingleton(() => GetDeliveryCodeUseCase(sl()))
    ..registerLazySingleton(() => GetProfileUseCase(sl()))
    ..registerLazySingleton(() => UpdateProfileUseCase(sl()))
    ..registerLazySingleton(() => WatchWalletLedgerUseCase(sl()))
    ..registerLazySingleton(() => GetWalletLedgerUseCase(sl()))
    ..registerLazySingleton(() => WatchLoyaltyLedgerUseCase(sl()))
    ..registerLazySingleton(() => GetLoyaltyLedgerUseCase(sl()))
    ..registerLazySingleton(() => GetLoyaltyProgramUseCase(sl()))
    ..registerLazySingleton(() => GetLoyaltyRewardsUseCase(sl()))
    // Presentation — the profile cubit takes the customer the app already
    // knows (from the session) so the form renders before the refresh lands.
    ..registerFactory(() => AccountCubit(sl()))
    ..registerFactory(() => DeliveryCodeCubit(sl()))
    ..registerFactoryParam<ProfileCubit, AuthCustomerEntity?, void>(
      (initial, _) =>
          ProfileCubit(getProfile: sl(), updateProfile: sl(), initial: initial),
    )
    ..registerFactory<LedgerCubit<WalletEntryEntity>>(
      () => LedgerCubit<WalletEntryEntity>(
        sl<WatchWalletLedgerUseCase>(),
        sl<GetWalletLedgerUseCase>(),
      ),
    )
    ..registerFactory<LedgerCubit<LoyaltyEntryEntity>>(
      () => LedgerCubit<LoyaltyEntryEntity>(
        sl<WatchLoyaltyLedgerUseCase>(),
        sl<GetLoyaltyLedgerUseCase>(),
      ),
    )
    ..registerFactory(() => LoyaltyProgramCubit(sl()))
    ..registerFactory(() => LoyaltyRewardsCubit(sl()));
}
