import '../../config/di/service_locator.dart';
import '../../core/data/jameia_repository.dart';
import 'data/datasources/orders_local_data_source.dart';
import 'data/repositories/orders_repository_impl.dart';
import 'domain/repositories/orders_repository.dart';
import 'presentation/cubit/order_invoice_cubit.dart';
import 'presentation/cubit/order_refund_cubit.dart';
import 'presentation/cubit/order_refund_detail_cubit.dart';
import 'presentation/cubit/order_review_cubit.dart';
import 'presentation/cubit/order_tracking_cubit.dart';
import 'presentation/cubit/orders_cubit.dart';

/// Orders feature DI — mirrors the cart / support templates (offline local
/// chain). Called from `main.dart` after [setupServiceLocator] (which registers
/// the loaded [JameiaRepository]). Cubits are `registerFactory` (fresh per
/// screen); the repository / datasource are `registerLazySingleton`. The former
/// pass-through use cases are collapsed — cubits call the repository directly.
void initOrdersFeature() {
  if (sl.isRegistered<OrdersRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<OrdersLocalDataSource>(
    () => OrdersLocalDataSourceImpl(sl<JameiaRepository>()),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(local: sl<OrdersLocalDataSource>()),
  );

  // Presentation (page-scoped cubits) — depend on the repository directly.
  sl.registerFactory(() => OrdersCubit(sl<OrdersRepository>()));
  sl.registerFactory(() => OrderTrackingCubit(sl<OrdersRepository>()));
  sl.registerFactory(() => OrderInvoiceCubit(sl<OrdersRepository>()));
  sl.registerFactory(() => OrderReviewCubit(sl<OrdersRepository>()));
  sl.registerFactory(() => OrderRefundCubit(sl<OrdersRepository>()));
  sl.registerFactory(() => OrderRefundDetailCubit(sl<OrdersRepository>()));
}
