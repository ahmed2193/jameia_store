import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/unread_notifications_state.dart';

import 'notifications_test_fakes.dart';

void main() {
  late FakeGetNotificationsUseCase getNotifications;
  late FakeWatchLiveNotificationsUseCase watchLive;

  final probe = feedOf(
    [notification()],
    page: 1,
    hasMore: true,
    total: 9,
    unreadCount: 5,
  );

  UnreadNotificationsCubit build() => UnreadNotificationsCubit(
    getNotifications: getNotifications,
    watchLive: watchLive,
  );

  setUp(() {
    getNotifications = FakeGetNotificationsUseCase(Right(probe));
    watchLive = FakeWatchLiveNotificationsUseCase();
  });

  tearDown(() async {
    if (!watchLive.controller.isClosed) await watchLive.controller.close();
  });

  group('start', () {
    blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
      'probes one item for unreadCount, then goes live',
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [
        const UnreadNotificationsState(unreadCount: 5),
        const UnreadNotificationsState(unreadCount: 5, isLive: true),
      ],
      verify: (_) {
        expect(getNotifications.calls, [
          const GetNotificationsParams(
            page: 1,
            limit: UnreadNotificationsCubit.probeLimit,
          ),
        ]);
        expect(UnreadNotificationsCubit.probeLimit, 1);
        expect(watchLive.listens, 1);
      },
    );

    blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
      'a guest (401) stays at zero and opens no stream',
      build: () {
        getNotifications.result = const Left(UnauthorizedFailure());
        return build();
      },
      act: (cubit) => cubit.start(),
      expect: () => <UnreadNotificationsState>[],
      verify: (_) {
        expect(getNotifications.calls.length, 1);
        expect(watchLive.listens, 0);
      },
    );

    blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
      'offline probe still listens live (the client reconnects by itself)',
      build: () {
        getNotifications.result = const Left(NetworkFailure());
        return build();
      },
      act: (cubit) => cubit.start(),
      expect: () => [const UnreadNotificationsState(isLive: true)],
      verify: (_) => expect(watchLive.listens, 1),
    );

    blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
      'is idempotent while running',
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.start();
      },
      verify: (_) {
        expect(getNotifications.calls.length, 1);
        expect(watchLive.listens, 1);
      },
    );

    blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
      'stop() during the probe cancels the start',
      build: build,
      act: (cubit) async {
        final starting = cubit.start();
        cubit.stop();
        await starting;
      },
      expect: () => <UnreadNotificationsState>[],
      verify: (_) => expect(watchLive.listens, 0),
    );
  });

  group('live events', () {
    blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
      'each unread notification adds one; read ones do not',
      build: build,
      act: (cubit) async {
        await cubit.start();
        watchLive.emit(notification(id: 'a'));
        watchLive.emit(notification(id: 'b', isRead: true));
        watchLive.emit(notification(id: 'c'));
      },
      skip: 2,
      expect: () => [
        const UnreadNotificationsState(unreadCount: 6, isLive: true),
        const UnreadNotificationsState(unreadCount: 7, isLive: true),
      ],
    );

    blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
      'a rejected stream drops isLive and keeps the count',
      build: build,
      act: (cubit) async {
        await cubit.start();
        await watchLive.fail(const ForbiddenFailure('No'));
      },
      skip: 2,
      expect: () => [const UnreadNotificationsState(unreadCount: 5)],
    );
  });

  blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
    'stop cancels the stream and resets to zero',
    build: build,
    act: (cubit) async {
      await cubit.start();
      cubit.stop();
    },
    skip: 2,
    expect: () => [const UnreadNotificationsState()],
    verify: (_) => expect(watchLive.controller.hasListener, isFalse),
  );

  blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
    'set overrides the count and clamps at zero',
    build: build,
    act: (cubit) => cubit
      ..set(3)
      ..set(-4),
    expect: () => [
      const UnreadNotificationsState(unreadCount: 3),
      const UnreadNotificationsState(),
    ],
  );

  blocTest<UnreadNotificationsCubit, UnreadNotificationsState>(
    'start after stop probes again',
    build: build,
    act: (cubit) async {
      await cubit.start();
      cubit.stop();
      await cubit.start();
    },
    verify: (_) {
      expect(getNotifications.calls.length, 2);
      expect(watchLive.listens, 2);
    },
  );

  test('close cancels the live subscription', () async {
    final cubit = build();
    await cubit.start();
    expect(watchLive.controller.hasListener, isTrue);

    await cubit.close();

    expect(watchLive.controller.hasListener, isFalse);
  });
}
