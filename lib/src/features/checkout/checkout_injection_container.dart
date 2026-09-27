import '../../config/di/service_locator.dart';
import '../../core/data/datasources/catalog_remote_data_source.dart';
import 'data/datasources/checkout_rail_data_source.dart';
import 'data/datasources/checkout_remote_data_source.dart';
import 'data/datasources/delivery_remote_data_source.dart';
import 'data/repositories/checkout_catalog_repository_impl.dart';
import 'data/repositories/checkout_repository_impl.dart';
import 'domain/repositories/checkout_catalog_repository.dart';
import 'domain/repositories/checkout_repository.dart';
import 'domain/usecases/get_branches_usecase.dart';
import 'domain/usecases/get_delivery_slots_usecase.dart';
import 'domain/usecases/get_rail_products_usecase.dart';
import 'domain/usecases/get_store_offers_usecase.dart';
import 'domain/usecases/get_store_rules_usecase.dart';
import 'domain/usecases/place_order_usecase.dart';
import 'domain/usecases/select_delivery_address_usecase.dart';
import 'domain/usecases/select_pickup_branch_usecase.dart';
import 'presentation/cubit/checkout_cubit.dart';
import 'presentation/cubit/checkout_offers_cubit.dart';
import 'presentation/cubit/checkout_rail_cubit.dart';

/// Checkout feature DI (`/v1/delivery/*`, `GET /v1/init`, `POST /v1/orders`,
/// and the rail / offers over the shared catalogue datasource). Called from
/// `setupServiceLocator` after the core catalogue registration.
void initCheckoutFeature() {
  if (sl.isRegistered<CheckoutRepository>()) return; // idempotent

  sl
    ..registerLazySingleton<DeliveryRemoteDataSource>(
      () => DeliveryRemoteDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<CheckoutRemoteDataSource>(
      () => CheckoutRemoteDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<CheckoutRepository>(
      () => CheckoutRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton<CheckoutRailDataSource>(
      () => CheckoutRailDataSourceImpl(sl<CatalogRemoteDataSource>(), sl()),
    )
    ..registerLazySingleton<CheckoutCatalogRepository>(
      () => CheckoutCatalogRepositoryImpl(sl(), sl<CatalogRemoteDataSource>()),
    )
    ..registerLazySingleton(() => GetBranchesUseCase(sl()))
    ..registerLazySingleton(() => GetDeliverySlotsUseCase(sl()))
    ..registerLazySingleton(() => SelectDeliveryAddressUseCase(sl()))
    ..registerLazySingleton(() => SelectPickupBranchUseCase(sl()))
    ..registerLazySingleton(() => PlaceOrderUseCase(sl()))
    ..registerLazySingleton(() => GetStoreRulesUseCase(sl()))
    ..registerLazySingleton(() => GetRailProductsUseCase(sl()))
    ..registerLazySingleton(() => GetStoreOffersUseCase(sl()))
    ..registerFactory(
      () => CheckoutCubit(
        getBranches: sl(),
        getDeliverySlots: sl(),
        selectDeliveryAddress: sl(),
        selectPickupBranch: sl(),
        placeOrder: sl(),
        getStoreRules: sl(),
      ),
    )
    ..registerFactory(() => CheckoutRailCubit(sl()))
    ..registerFactory(() => CheckoutOffersCubit(sl()));
}
