import '../../config/di/service_locator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/data/datasources/cache_slots.dart';
import 'data/datasources/courier_store_data_source.dart';
import 'data/datasources/courier_tracking_data_source.dart';
import 'data/datasources/demo_courier_tracking_data_source.dart';
import 'data/datasources/demo_rider_chat_data_source.dart';
import 'data/datasources/fallback_road_route_data_source.dart';
import 'data/datasources/google_road_route_data_source.dart';
import 'data/datasources/orders_cache_data_source.dart';
import 'data/datasources/orders_remote_data_source.dart';
import 'data/datasources/osrm_road_route_data_source.dart';
import 'data/datasources/rider_chat_data_source.dart';
import 'data/datasources/road_route_data_source.dart';
import 'data/datasources/tracking_alerts_data_source.dart';
import 'data/repositories/courier_tracking_repository_impl.dart';
import 'data/repositories/orders_repository_impl.dart';
import 'data/repositories/rider_chat_repository_impl.dart';
import 'data/repositories/tracking_alerts_repository_impl.dart';
import 'domain/repositories/courier_tracking_repository.dart';
import 'domain/repositories/orders_repository.dart';
import 'domain/repositories/rider_chat_repository.dart';
import 'domain/repositories/tracking_alerts_repository.dart';
import 'domain/usecases/allow_tracking_alerts_usecase.dart';
import 'domain/usecases/cancel_order_usecase.dart';
import 'domain/usecases/check_tracking_alerts_usecase.dart';
import 'domain/usecases/clear_tracking_alert_usecase.dart';
import 'domain/usecases/get_courier_trip_usecase.dart';
import 'domain/usecases/get_order_usecase.dart';
import 'domain/usecases/get_orders_usecase.dart';
import 'domain/usecases/mark_rider_chat_read_usecase.dart';
import 'domain/usecases/send_rider_message_usecase.dart';
import 'domain/usecases/show_tracking_alert_usecase.dart';
import 'domain/usecases/submit_product_review_usecase.dart';
import 'domain/usecases/watch_courier_usecase.dart';
import 'domain/usecases/watch_order_usecase.dart';
import 'domain/usecases/watch_orders_usecase.dart';
import 'domain/usecases/watch_rider_chat_usecase.dart';
import 'presentation/cubit/courier_tracking_cubit.dart';
import 'presentation/cubit/order_invoice_cubit.dart';
import 'presentation/cubit/order_review_cubit.dart';
import 'presentation/cubit/order_tracking_cubit.dart';
import 'presentation/cubit/orders_cubit.dart';
import 'presentation/cubit/rider_chat_cubit.dart';
import 'presentation/cubit/tracking_alerts_cubit.dart';

/// Orders feature DI (`/v1/orders*`, `POST /v1/reviews`; the first page and
/// each order opened are kept on the device for the signed-in customer), and
/// the live rider map — on a simulated feed until the backend tracks riders
/// (one feed for the app's life, so a ride keeps its clock across opens),
/// driven on real roads: Google's Routes API when `MAPS_API_KEY` is set (and
/// the Routes API is enabled for it), else OpenStreetMap roads (OSRM).
/// Called from `setupServiceLocator`.
void initOrdersFeature() {
  if (sl.isRegistered<OrdersRepository>()) return; // idempotent

  sl
    ..registerLazySingleton<OrdersRemoteDataSource>(
      () => OrdersRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<OrdersCacheDataSource>(
      () => OrdersCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<OrdersRepository>(
      () => OrdersRepositoryImpl(sl(), cache: sl()),
    )
    ..registerLazySingleton(() => WatchOrdersUseCase(sl()))
    ..registerLazySingleton(() => GetOrdersUseCase(sl()))
    ..registerLazySingleton(() => WatchOrderUseCase(sl()))
    ..registerLazySingleton(() => GetOrderUseCase(sl()))
    ..registerLazySingleton(() => CancelOrderUseCase(sl()))
    ..registerLazySingleton(() => SubmitProductReviewUseCase(sl()))
    ..registerFactory(
      () => OrdersCubit(
        watchFirstPage: sl(),
        getOrders: sl(),
        getOrder: sl(),
        cancelOrder: sl(),
      ),
    )
    ..registerFactory(
      () => OrderTrackingCubit(watchOrder: sl(), cancelOrder: sl()),
    )
    ..registerFactory(
      () => OrderReviewCubit(watchOrder: sl(), submitReview: sl()),
    )
    ..registerFactory(() => OrderInvoiceCubit(watchOrder: sl()))
    ..registerLazySingleton<CourierStoreDataSource>(
      () => CourierStoreRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<RoadRouteDataSource>(
      () => FallbackRoadRouteDataSource([
        if (AppConstants.mapsApiKey.isNotEmpty)
          GoogleRoadRouteDataSource(sl(), apiKey: AppConstants.mapsApiKey),
        OsrmRoadRouteDataSource(sl()),
      ]),
    )
    ..registerLazySingleton<CourierTrackingDataSource>(
      () => DemoCourierTrackingDataSource(stores: sl(), roads: sl()),
    )
    ..registerLazySingleton<CourierTrackingRepository>(
      () => CourierTrackingRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetCourierTripUseCase(sl()))
    ..registerLazySingleton(() => WatchCourierUseCase(sl()))
    ..registerFactory(
      () => CourierTrackingCubit(getTrip: sl(), watchCourier: sl()),
    )
    ..registerLazySingleton<TrackingAlertsDataSource>(
      () => TrackingAlertsDataSourceImpl(sl()),
    )
    ..registerLazySingleton<TrackingAlertsRepository>(
      () => TrackingAlertsRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => CheckTrackingAlertsUseCase(sl()))
    ..registerLazySingleton(() => AllowTrackingAlertsUseCase(sl()))
    ..registerLazySingleton(() => ShowTrackingAlertUseCase(sl()))
    ..registerLazySingleton(() => ClearTrackingAlertUseCase(sl()))
    ..registerFactory(
      () => TrackingAlertsCubit(
        check: sl(),
        allow: sl(),
        show: sl(),
        clear: sl(),
      ),
    )
    // The rider chat — simulated like the rider feed until the backend has
    // one (one conversation per ride, kept for the app's life).
    ..registerLazySingleton<RiderChatDataSource>(
      () => DemoRiderChatDataSource(
        ride: sl<CourierTrackingDataSource>().watchCourier,
      ),
    )
    ..registerLazySingleton<RiderChatRepository>(
      () => RiderChatRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => WatchRiderChatUseCase(sl()))
    ..registerLazySingleton(() => SendRiderMessageUseCase(sl()))
    ..registerLazySingleton(() => MarkRiderChatReadUseCase(sl()))
    ..registerFactory(
      () => RiderChatCubit(watch: sl(), send: sl(), markRead: sl()),
    );
}
