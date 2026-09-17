import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notifications_feed.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../mappers/notification_mapper.dart';

class NotificationsRepositoryImpl
    with BaseRepositoryMixin
    implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<Either<Failure, NotificationsFeed>> getNotifications({
    required int page,
    required int limit,
    bool unreadOnly = false,
  }) => execute(
    () async => (await _remote.getNotifications(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    )).toEntity(),
  );

  @override
  Future<Either<Failure, NotificationEntity>> markRead(String id) =>
      execute(() async => (await _remote.markRead(id)).toEntity());

  @override
  Future<Either<Failure, int>> markAllRead() =>
      execute(() => _remote.markAllRead());

  @override
  Future<Either<Failure, Unit>> registerPushToken({
    required String token,
    required String platform,
  }) => execute(() async {
    await _remote.registerPushToken(token: token, platform: platform);
    return unit;
  });

  /// A server rejection (401 after refresh, 403 …) reaches the subscriber as
  /// a stream error carrying the mapped `Failure` — never an exception type.
  @override
  Stream<NotificationEntity> watchLive() =>
      guardStream(_remote.watchLive().map((model) => model.toEntity()));
}
