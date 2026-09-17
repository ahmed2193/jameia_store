import '../../config/di/service_locator.dart';
import 'data/datasources/notifications_remote_data_source.dart';
import 'data/repositories/notifications_repository_impl.dart';
import 'domain/repositories/notifications_repository.dart';
import 'domain/usecases/get_notifications_usecase.dart';
import 'domain/usecases/mark_all_notifications_read_usecase.dart';
import 'domain/usecases/mark_notification_read_usecase.dart';
import 'domain/usecases/register_push_token_usecase.dart';
import 'domain/usecases/watch_live_notifications_usecase.dart';
import 'presentation/cubit/notifications_cubit.dart';
import 'presentation/cubit/unread_notifications_cubit.dart';

/// Notifications feature DI — the customer inbox + push registration over the
/// jm3eia API. Depends on the core `ApiConsumer` and `EventStreamClient`
/// registered by `setupServiceLocator` before any feature init.
void initNotificationsFeature() {
  if (sl.isRegistered<NotificationsRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetNotificationsUseCase(sl()))
    ..registerLazySingleton(() => MarkNotificationReadUseCase(sl()))
    ..registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()))
    ..registerLazySingleton(() => RegisterPushTokenUseCase(sl()))
    ..registerLazySingleton(() => WatchLiveNotificationsUseCase(sl()))
    // Presentation — the inbox cubit is page-scoped; the unread cubit is
    // app-global (provided once above MaterialApp.router) but also a factory
    // so tests and a future re-provide get a fresh instance.
    ..registerFactory(
      () => NotificationsCubit(
        getNotifications: sl(),
        markRead: sl(),
        markAllRead: sl(),
        watchLive: sl(),
      ),
    )
    ..registerFactory(
      () => UnreadNotificationsCubit(getNotifications: sl(), watchLive: sl()),
    );
}
