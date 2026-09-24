import '../../config/di/service_locator.dart';
import 'data/datasources/checkout_remote_data_source.dart';
import 'data/datasources/delivery_remote_data_source.dart';
import 'data/repositories/checkout_repository_impl.dart';
import 'domain/repositories/checkout_repository.dart';
import 'domain/usecases/get_branches_usecase.dart';
import 'domain/usecases/get_delivery_slots_usecase.dart';
import 'domain/usecases/place_order_usecase.dart';
import 'domain/usecases/select_delivery_address_usecase.dart';
import 'domain/usecases/select_pickup_branch_usecase.dart';
import 'presentation/cubit/checkout_cubit.dart';

/// Checkout feature DI (`/v1/delivery/*`, `POST /v1/orders`). Called from
/// `setupServiceLocator`.
void initCheckoutFeature() {
  if (sl.isRegistered<CheckoutRepository>()) return; // idempotent

  sl
    ..registerLazySingleton<DeliveryRemoteDataSource>(
      () => DeliveryRemoteDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<CheckoutRemoteDataSource>(
      () => CheckoutRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<CheckoutRepository>(
      () => CheckoutRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton(() => GetBranchesUseCase(sl()))
    ..registerLazySingleton(() => GetDeliverySlotsUseCase(sl()))
    ..registerLazySingleton(() => SelectDeliveryAddressUseCase(sl()))
    ..registerLazySingleton(() => SelectPickupBranchUseCase(sl()))
    ..registerLazySingleton(() => PlaceOrderUseCase(sl()))
    ..registerFactory(
      () => CheckoutCubit(
        getBranches: sl(),
        getDeliverySlots: sl(),
        selectDeliveryAddress: sl(),
        selectPickupBranch: sl(),
        placeOrder: sl(),
      ),
    );
}
