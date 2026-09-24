import '../../config/di/service_locator.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/entities/phone_number.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/clear_cached_customer_usecase.dart';
import 'domain/usecases/get_cached_customer_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/restore_session_usecase.dart';
import 'domain/usecases/save_cached_customer_usecase.dart';
import 'domain/usecases/send_otp_usecase.dart';
import 'domain/usecases/verify_otp_usecase.dart';
import 'domain/usecases/watch_session_expiry_usecase.dart';
import 'presentation/cubit/auth_session_cubit.dart';
import 'presentation/cubit/login_cubit.dart';
import 'presentation/cubit/otp_cubit.dart';

/// Auth feature DI — the OTP login flow over the jm3eia API and the device
/// copy of the signed-in customer. Depends on the core `ApiConsumer`,
/// `SessionStore`, `SessionExpiryNotifier` and `LocalStorage` registered by
/// `setupServiceLocator` before any feature init.
void initAuthFeature() {
  if (sl.isRegistered<AuthRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl(), sl(), sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: sl(), local: sl()),
    )
    // Domain
    ..registerLazySingleton(() => SendOtpUseCase(sl()))
    ..registerLazySingleton(() => VerifyOtpUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    ..registerLazySingleton(() => RestoreSessionUseCase(sl()))
    ..registerLazySingleton(() => WatchSessionExpiryUseCase(sl()))
    ..registerLazySingleton(() => GetCachedCustomerUseCase(sl()))
    ..registerLazySingleton(() => SaveCachedCustomerUseCase(sl()))
    ..registerLazySingleton(() => ClearCachedCustomerUseCase(sl()))
    // Presentation — page-scoped cubits are factories; the OTP cubit takes the
    // phone (+ optional echoed code) from the route args.
    ..registerFactory(() => LoginCubit(sl()))
    ..registerFactoryParam<OtpCubit, PhoneNumber, String?>(
      (phone, debugCode) => OtpCubit(
        sendOtp: sl(),
        verifyOtp: sl(),
        phone: phone,
        debugCode: debugCode,
      ),
    )
    // App-global (provided once above MaterialApp.router via AppGlobalCubits).
    ..registerFactory(
      () => AuthSessionCubit(
        restoreSession: sl(),
        logout: sl(),
        watchExpiry: sl(),
        getCachedCustomer: sl(),
        saveCachedCustomer: sl(),
        clearCachedCustomer: sl(),
      ),
    );
}
