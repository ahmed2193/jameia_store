import '../../config/di/service_locator.dart';
import '../../core/constants/app_env.dart';
import '../../core/data/datasources/cache_slots.dart';
import 'data/datasources/notifications_cache_data_source.dart';
import 'data/datasources/notifications_remote_data_source.dart';
import 'data/repositories/notifications_repository_impl.dart';
import 'domain/repositories/notifications_repository.dart';
import 'domain/usecases/get_notifications_usecase.dart';
import 'domain/usecases/mark_all_notifications_read_usecase.dart';
import 'domain/usecases/mark_notification_read_usecase.dart';
import 'domain/usecases/register_push_token_usecase.dart';
import 'domain/usecases/watch_live_notifications_usecase.dart';
import 'domain/usecases/watch_notifications_usecase.dart';
import 'presentation/cubit/notifications_cubit.dart';
import 'presentation/cubit/unread_notifications_cubit.dart';

/// Notifications feature DI — the customer inbox + push registration over the
/// jm3eia API (the inbox's first page is kept on the device for the
/// signed-in customer). Depends on the core `ApiConsumer`,
/// `EventStreamClient` and `CacheSlots` registered by `setupServiceLocator`
/// before any feature init.
void initNotificationsFeature() {
  if (sl.isRegistered<NotificationsRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<NotificationsCacheDataSource>(
      () => NotificationsCacheDataSourceImpl(sl<CacheSlots>()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl(), cache: sl()),
    )
    // Domain
    ..registerLazySingleton(() => WatchNotificationsUseCase(sl()))
    ..registerLazySingleton(() => GetNotificationsUseCase(sl()))
    ..registerLazySingleton(() => MarkNotificationReadUseCase(sl()))
    ..registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()))
    ..registerLazySingleton(() => RegisterPushTokenUseCase(sl()))
    ..registerLazySingleton(() => WatchLiveNotificationsUseCase(sl()))
    // Presentation — the inbox cubit is page-scoped; the unread cubit is
    // app-global (provided once above MaterialApp.router) but also a factory
    // so tests and a future re-provide get a fresh instance. Neither opens
    // the live stream unless the build asks for it (AppEnv.liveNotifications).
    ..registerFactory(
      () => NotificationsCubit(
        watchFirstPage: sl(),
        getNotifications: sl(),
        markRead: sl(),
        markAllRead: sl(),
        watchLive: _liveSource(),
      ),
    )
    ..registerFactory(
      () => UnreadNotificationsCubit(
        getNotifications: sl(),
        watchLive: _liveSource(),
      ),
    );
}

/// The live notifications stream, or `null` when this build keeps it closed.
WatchLiveNotificationsUseCase? _liveSource() =>
    AppEnv.liveNotifications ? sl<WatchLiveNotificationsUseCase>() : null;
