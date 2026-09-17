import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../entities/notifications_feed.dart';

/// Customer inbox over the jm3eia notifications API. Every call needs a
/// signed-in customer (Bearer attached by the network layer); a guest gets
/// `Left(UnauthorizedFailure)`.
///
/// Reference: https://docs.jm3eia.store/developers/ (Notifications, Push).
abstract class NotificationsRepository {
  /// `GET /v1/notifications?page&limit[&status=unread]` — one page plus the
  /// global unread counter.
  Future<Either<Failure, NotificationsFeed>> getNotifications({
    required int page,
    required int limit,
    bool unreadOnly = false,
  });

  /// `PATCH /v1/notifications/:id/read` → the updated notification.
  Future<Either<Failure, NotificationEntity>> markRead(String id);

  /// `PATCH /v1/notifications/read-all` → how many were updated.
  Future<Either<Failure, int>> markAllRead();

  /// `POST /v1/push/register { token, platform }` — [platform] is `ios` or
  /// `android`.
  Future<Either<Failure, Unit>> registerPushToken({
    required String token,
    required String platform,
  });

  /// `GET /v1/notifications/sse` — new notifications as they happen. The
  /// stream reconnects by itself on connection loss and only errors — with a
  /// `Failure` (e.g. `UnauthorizedFailure`) as the error object — when the
  /// server rejects the connection.
  Stream<NotificationEntity> watchLive();
}
