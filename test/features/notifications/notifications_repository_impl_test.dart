import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:jameia_mart/src/features/notifications/domain/entities/notification_entity.dart';
import 'package:jameia_mart/src/features/notifications/domain/entities/notifications_feed.dart';

import 'notifications_test_fakes.dart';

void main() {
  late FakeNotificationsRemoteDataSource remote;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    remote = FakeNotificationsRemoteDataSource();
    repository = NotificationsRepositoryImpl(remote);
  });

  test('getNotifications forwards the query and maps to a feed', () async {
    final result = await repository.getNotifications(
      page: 2,
      limit: 20,
      unreadOnly: true,
    );

    expect(remote.calls, ['get:2:20:true']);
    expect(
      result,
      Right<Failure, NotificationsFeed>(
        feedOf([notification()], page: 1, unreadCount: 1),
      ),
    );
  });

  test('getNotifications maps a guest 401 to UnauthorizedFailure', () async {
    remote.error = const UnauthorizedException(
      'Sign in',
      code: 'AUTHENTICATION_REQUIRED',
    );

    final result = await repository.getNotifications(page: 1, limit: 20);

    expect(
      result,
      const Left<Failure, NotificationsFeed>(UnauthorizedFailure('Sign in')),
    );
  });

  test('getNotifications maps transport failures', () async {
    remote.error = const NoInternetConnectionException();
    expect(
      await repository.getNotifications(page: 1, limit: 20),
      const Left<Failure, NotificationsFeed>(
        NetworkFailure('No internet connection'),
      ),
    );

    remote.error = const ParsingException('bad');
    expect(
      await repository.getNotifications(page: 1, limit: 20),
      const Left<Failure, NotificationsFeed>(ParsingFailure('bad')),
    );
  });

  test('markRead returns the server copy as an entity', () async {
    final result = await repository.markRead('n1');

    expect(remote.calls, ['read:n1']);
    expect(
      result,
      Right<Failure, NotificationEntity>(notification(isRead: true)),
    );
  });

  test('markRead maps a 404 to ServerFailure with the code', () async {
    remote.error = const NotFoundException('Gone', code: 'NOT_FOUND');

    final result = await repository.markRead('n1');

    expect(
      result,
      const Left<Failure, NotificationEntity>(
        ServerFailure('Gone', statusCode: 404, code: 'NOT_FOUND'),
      ),
    );
  });

  test('markAllRead returns the updated count', () async {
    remote.updatedCount = 8;
    expect(await repository.markAllRead(), const Right<Failure, int>(8));
    expect(remote.calls, ['read-all']);
  });

  test(
    'registerPushToken forwards token + platform and returns unit',
    () async {
      final result = await repository.registerPushToken(
        token: 'fcm-token-1234567890',
        platform: 'ios',
      );

      expect(remote.calls, ['push:fcm-token-1234567890:ios']);
      expect(result, const Right<Failure, Unit>(unit));
    },
  );

  test('registerPushToken maps a 400 to ServerFailure', () async {
    remote.error = const BadRequestException(
      'Token too short',
      code: 'VALIDATION_ERROR',
    );

    final result = await repository.registerPushToken(
      token: 'short',
      platform: 'ios',
    );

    expect(
      result,
      const Left<Failure, Unit>(
        ServerFailure(
          'Token too short',
          statusCode: 400,
          code: 'VALIDATION_ERROR',
        ),
      ),
    );
  });

  test('watchLive maps models to entities in order', () async {
    remote.live = Stream.fromIterable([
      notificationModel(id: 'a'),
      notificationModel(id: 'b', isRead: true),
    ]);

    final entities = await repository.watchLive().toList();

    expect(entities, [
      notification(id: 'a'),
      notification(id: 'b', isRead: true),
    ]);
  });

  test(
    'watchLive surfaces a server rejection as its Failure, not an exception',
    () {
      remote.live = Stream.error(const UnauthorizedException('Sign in'));

      expect(
        repository.watchLive(),
        emitsError(
          isA<UnauthorizedFailure>().having(
            (f) => f.message,
            'message',
            'Sign in',
          ),
        ),
      );
    },
  );
}
