import '../../config/di/service_locator.dart';
import 'data/datasources/cart_local_data_source.dart';
import 'data/datasources/cart_remote_data_source.dart';
import 'data/repositories/cart_repository_impl.dart';
import 'domain/repositories/cart_repository.dart';
import 'domain/usecases/add_cart_items_usecase.dart';
import 'domain/usecases/adjust_cart_line_usecase.dart';
import 'domain/usecases/apply_cart_coupon_usecase.dart';
import 'domain/usecases/apply_cart_loyalty_usecase.dart';
import 'domain/usecases/clear_cart_usecase.dart';
import 'domain/usecases/fetch_cart_usecase.dart';
import 'domain/usecases/flush_cart_usecase.dart';
import 'domain/usecases/remove_cart_coupon_usecase.dart';
import 'domain/usecases/remove_cart_line_usecase.dart';
import 'domain/usecases/remove_cart_loyalty_usecase.dart';
import 'domain/usecases/reset_cart_usecase.dart';
import 'domain/usecases/restore_cart_usecase.dart';
import 'domain/usecases/set_cart_express_usecase.dart';
import 'domain/usecases/set_cart_line_quantity_usecase.dart';
import 'domain/usecases/sync_cart_owner_usecase.dart';
import 'domain/usecases/watch_cart_usecase.dart';
import 'presentation/cubit/cart_cubit.dart';

/// Cart feature DI (`/v1/cart*` + the on-device mirror). Called from
/// `setupServiceLocator`.
Future<void> initCartFeature() async {
  if (sl.isRegistered<CartRepository>()) return; // idempotent

  sl
    ..registerLazySingleton<CartRemoteDataSource>(
      () => CartRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton(() => WatchCartUseCase(sl()))
    ..registerLazySingleton(() => RestoreCartUseCase(sl()))
    ..registerLazySingleton(() => SyncCartOwnerUseCase(sl()))
    ..registerLazySingleton(() => FetchCartUseCase(sl()))
    ..registerLazySingleton(() => FlushCartUseCase(sl()))
    ..registerLazySingleton(() => AdjustCartLineUseCase(sl()))
    ..registerLazySingleton(() => SetCartLineQuantityUseCase(sl()))
    ..registerLazySingleton(() => RemoveCartLineUseCase(sl()))
    ..registerLazySingleton(() => AddCartItemsUseCase(sl()))
    ..registerLazySingleton(() => ClearCartUseCase(sl()))
    ..registerLazySingleton(() => ApplyCartCouponUseCase(sl()))
    ..registerLazySingleton(() => RemoveCartCouponUseCase(sl()))
    ..registerLazySingleton(() => ApplyCartLoyaltyUseCase(sl()))
    ..registerLazySingleton(() => RemoveCartLoyaltyUseCase(sl()))
    ..registerLazySingleton(() => SetCartExpressUseCase(sl()))
    ..registerLazySingleton(() => ResetCartUseCase(sl()))
    // App-root cubit, fresh per BlocProvider mount; `start()` subscribes.
    ..registerFactory<CartCubit>(
      () => CartCubit(
        watch: sl(),
        restore: sl(),
        syncOwner: sl(),
        fetch: sl(),
        flush: sl(),
        adjustLine: sl(),
        setLineQuantity: sl(),
        removeLine: sl(),
        addItems: sl(),
        clear: sl(),
        applyCoupon: sl(),
        removeCoupon: sl(),
        applyLoyalty: sl(),
        removeLoyalty: sl(),
        setExpress: sl(),
        reset: sl(),
      ),
    );
}
