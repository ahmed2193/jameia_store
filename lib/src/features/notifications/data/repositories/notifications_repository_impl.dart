import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notifications_feed.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_cache_data_source.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../mappers/notification_mapper.dart';

class NotificationsRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote, {required this._cache});

  final NotificationsRemoteDataSource _remote;
  final NotificationsCacheDataSource _cache;

  static const int _firstPage = 1;

  @override
  Stream<DataSnapshot<NotificationsFeed>> watchFirstPage({
    required int limit,
    bool unreadOnly = false,
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.firstPage(limit: limit, unreadOnly: unreadOnly),
    fetch: () => _remote.getNotifications(
      page: _firstPage,
      limit: limit,
      unreadOnly: unreadOnly,
    ),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

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
    )).model.toEntity(),
  );

  /// A read mark that reached the server makes the saved pages out of date:
  /// they are forgotten, so the next open asks the server.
  @override
  Future<Either<Failure, NotificationEntity>> markRead(String id) =>
      execute(() async {
        final updated = await _remote.markRead(id);
        unawaited(_cache.forgetPages());
        return updated.toEntity();
      });

  @override
  Future<Either<Failure, int>> markAllRead() => execute(() async {
    final marked = await _remote.markAllRead();
    unawaited(_cache.forgetPages());
    return marked;
  });

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
