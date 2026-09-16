import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/coupons_local_data_source.dart';
import 'data/repositories/coupons_repository_impl.dart';
import 'domain/repositories/coupons_repository.dart';
import 'domain/usecases/get_coupons_usecase.dart';
import 'presentation/cubit/coupons_cubit.dart';

/// Coupons feature DI — mirrors the cart/support templates (offline local chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). The single [CouponsCubit] is `registerFactory`
/// (fresh per screen — reused by My coupons / Coupon history / Order coupons);
/// the use case / repository / datasource are `registerLazySingleton`.
void initCouponsFeature() {
  if (sl.isRegistered<CouponsRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<CouponsLocalDataSource>(
      () => CouponsLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<CouponsRepository>(
      () => CouponsRepositoryImpl(local: sl<CouponsLocalDataSource>()));

  // Domain (use cases)
  sl.registerLazySingleton(() => GetCouponsUseCase(sl<CouponsRepository>()));

  // Presentation (page-scoped cubit shared by the three coupon screens)
  sl.registerFactory(() => CouponsCubit(sl<GetCouponsUseCase>()));
}
