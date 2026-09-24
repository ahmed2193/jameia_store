import '../../config/di/service_locator.dart';
import 'data/datasources/orders_remote_data_source.dart';
import 'data/repositories/orders_repository_impl.dart';
import 'domain/repositories/orders_repository.dart';
import 'domain/usecases/cancel_order_usecase.dart';
import 'domain/usecases/get_order_usecase.dart';
import 'domain/usecases/get_orders_usecase.dart';
import 'domain/usecases/submit_product_review_usecase.dart';
import 'presentation/cubit/order_invoice_cubit.dart';
import 'presentation/cubit/order_review_cubit.dart';
import 'presentation/cubit/order_tracking_cubit.dart';
import 'presentation/cubit/orders_cubit.dart';

/// Orders feature DI (`/v1/orders*`, `POST /v1/reviews`). Called from
/// `setupServiceLocator`.
void initOrdersFeature() {
  if (sl.isRegistered<OrdersRepository>()) return; // idempotent

  sl
    ..registerLazySingleton<OrdersRemoteDataSource>(
      () => OrdersRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<OrdersRepository>(() => OrdersRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetOrdersUseCase(sl()))
    ..registerLazySingleton(() => GetOrderUseCase(sl()))
    ..registerLazySingleton(() => CancelOrderUseCase(sl()))
    ..registerLazySingleton(() => SubmitProductReviewUseCase(sl()))
    ..registerFactory(
      () => OrdersCubit(getOrders: sl(), getOrder: sl(), cancelOrder: sl()),
    )
    ..registerFactory(
      () => OrderTrackingCubit(getOrder: sl(), cancelOrder: sl()),
    )
    ..registerFactory(
      () => OrderReviewCubit(getOrder: sl(), submitReview: sl()),
    )
    ..registerFactory(() => OrderInvoiceCubit(getOrder: sl()));
}
