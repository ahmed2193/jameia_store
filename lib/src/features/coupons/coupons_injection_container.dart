import '../../config/di/service_locator.dart';
import 'data/datasources/coupons_local_data_source.dart';
import 'data/repositories/coupons_repository_impl.dart';
import 'domain/repositories/coupons_repository.dart';
import 'domain/usecases/get_coupons_usecase.dart';
import 'presentation/cubit/coupons_cubit.dart';

/// Coupons feature DI (offline local chain). The [CouponsCubit] is a factory
/// (one per coupon screen: My coupons, history); the use case, repository and
/// datasource are lazy singletons.
void initCouponsFeature() {
  if (sl.isRegistered<CouponsRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<CouponsLocalDataSource>(
      () => CouponsLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<CouponsRepository>(
      () => CouponsRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetCouponsUseCase(sl()))
    ..registerFactory(() => CouponsCubit(sl()));
}
