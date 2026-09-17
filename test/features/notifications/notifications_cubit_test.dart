import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/notifications_state.dart';

import 'notifications_test_fakes.dart';

void main() {
  late FakeGetNotificationsUseCase getNotifications;
  late FakeMarkNotificationReadUseCase markRead;
  late FakeMarkAllNotificationsReadUseCase markAllRead;
  late FakeWatchLiveNotificationsUseCase watchLive;

  final n1 = notification(id: 'n1');
  final n2 = notification(id: 'n2', isRead: true);
  final n3 = notification(id: 'n3');
  final page1 = feedOf(
    [n1, n2],
    page: 1,
    hasMore: true,
    total: 3,
    unreadCount: 5,
  );
  final page2 = feedOf([n3], page: 2, hasMore: false, total: 3, unreadCount: 5);
  final loaded = NotificationsState(
    status: NotificationsStatus.loaded,
    feed: page1,
  );

  NotificationsCubit build() => NotificationsCubit(
    getNotifications: getNotifications,
    markRead: markRead,
    markAllRead: markAllRead,
    watchLive: watchLive,
  );

  setUp(() {
    getNotifications = FakeGetNotificationsUseCase(Right(page1));
    markRead = FakeMarkNotificationReadUseCase(
      Right(n1.copyWith(isRead: true)),
    );
    markAllRead = FakeMarkAllNotificationsReadUseCase(const Right(2));
    watchLive = FakeWatchLiveNotificationsUseCase();
  });

  tearDown(() async {
    if (!watchLive.controller.isClosed) await watchLive.controller.close();
  });

  group('load', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'loading → loaded with page 1 (pageSize 20) and the live stream open',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const NotificationsState(status: NotificationsStatus.loading),
        loaded,
      ],
      verify: (_) {
        expect(getNotifications.calls, [
          const GetNotificationsParams(
            page: 1,
            limit: NotificationsCubit.pageSize,
          ),
        ]);
        expect(NotificationsCubit.pageSize, 20);
        expect(watchLive.listens, 1);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'failure → error with the failure and no live stream',
      build: () {
        getNotifications.result = const Left(UnauthorizedFailure('Sign in'));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const NotificationsState(status: NotificationsStatus.loading),
        const NotificationsState(
          status: NotificationsStatus.error,
          failure: UnauthorizedFailure('Sign in'),
          failedAction: NotificationsAction.load,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.isSignedOut, isTrue);
        expect(watchLive.listens, 0);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'a second load reuses the open live subscription',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.load();
      },
      verify: (_) => expect(watchLive.listens, 1),
    );
  });

  group('refresh', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'replaces the feed without a loading state',
      build: () {
        getNotifications.result = Right(page2);
        return build();
      },
      seed: () => loaded,
      act: (cubit) => cubit.refresh(),
      expect: () => [loaded.copyWith(feed: page2)],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'failure keeps the list and surfaces the failure',
      build: () {
        getNotifications.result = const Left(NetworkFailure());
        return build();
      },
      seed: () => loaded,
      act: (cubit) => cubit.refresh(),
      expect: () => [
        loaded.copyWith(
          failure: const NetworkFailure(),
          failedAction: NotificationsAction.refresh,
        ),
      ],
    );
  });

  group('loadMore', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'requests the next page and merges it',
      build: () {
        getNotifications.handler = (params) =>
            params.page == 2 ? Right(page2) : Right(page1);
        return build();
      },
      seed: () => loaded,
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(feed: page1.merge(page2)),
      ],
      verify: (cubit) {
        expect(getNotifications.calls.single.page, 2);
        expect(cubit.state.feed.items, [n1, n2, n3]);
        expect(cubit.state.feed.hasMore, isFalse);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'no-op when the server has no more',
      build: build,
      seed: () => loaded.copyWith(feed: page1.merge(page2)),
      act: (cubit) => cubit.loadMore(),
      expect: () => <NotificationsState>[],
      verify: (_) => expect(getNotifications.calls, isEmpty),
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'no-op while a page is in flight',
      build: build,
      seed: () => loaded.copyWith(isLoadingMore: true),
      act: (cubit) => cubit.loadMore(),
      expect: () => <NotificationsState>[],
      verify: (_) => expect(getNotifications.calls, isEmpty),
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'failure clears the flag and reports loadMore',
      build: () {
        getNotifications.result = const Left(TimeoutFailure());
        return build();
      },
      seed: () => loaded,
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(
          loadMoreFailed: true,
          failure: const TimeoutFailure(),
          failedAction: NotificationsAction.loadMore,
        ),
      ],
    );

    test(
      'a page that was in flight when a refresh landed is dropped',
      () async {
        // loadMore(page 2) is held; a pull-to-refresh replaces the list; the
        // stale page 2 must NOT be appended onto the fresh page 1.
        final fresh = feedOf(
          [notification(id: 'fresh')],
          page: 1,
          hasMore: true,
        );
        getNotifications
          ..gates[2] = Completer<void>()
          ..handler = (params) => Right(params.page == 1 ? fresh : page2);
        final cubit = build()..emit(loaded);

        final loadingMore = cubit.loadMore();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.isLoadingMore, isTrue);

        await cubit.refresh();
        expect(cubit.state.feed, fresh);
        expect(cubit.state.isLoadingMore, isFalse);

        getNotifications.gates[2]!.complete();
        await loadingMore;

        expect(cubit.state.feed, fresh, reason: 'stale page 2 ignored');
        expect(cubit.state.isLoadingMore, isFalse);
        await cubit.close();
      },
    );
  });

  group('markRead', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'flips the row optimistically; the server copy confirms it',
      build: build,
      seed: () => loaded,
      act: (cubit) => cubit.markRead('n1'),
      expect: () => [loaded.copyWith(feed: page1.markRead('n1'))],
      verify: (cubit) {
        expect(markRead.calls.single.id, 'n1');
        expect(cubit.state.feed.unreadCount, 4);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'reverts and reports the failure when the server refuses',
      build: () {
        markRead.result = const Left(ServerFailure('Nope', statusCode: 500));
        return build();
      },
      seed: () => loaded,
      act: (cubit) => cubit.markRead('n1'),
      expect: () => [
        loaded.copyWith(feed: page1.markRead('n1')),
        loaded.copyWith(
          failure: const ServerFailure('Nope', statusCode: 500),
          failedAction: NotificationsAction.markRead,
        ),
      ],
      verify: (cubit) => expect(cubit.state.feed.byId('n1')!.isRead, isFalse),
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'ignores already-read and unknown ids',
      build: build,
      seed: () => loaded,
      act: (cubit) async {
        await cubit.markRead('n2');
        await cubit.markRead('missing');
      },
      expect: () => <NotificationsState>[],
      verify: (_) => expect(markRead.calls, isEmpty),
    );
  });

  group('markAllRead', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'marks everything read locally after the server did, with the toast flag',
      build: build,
      seed: () => loaded,
      act: (cubit) => cubit.markAllRead(),
      expect: () => [
        loaded.copyWith(feed: page1.markAllRead(), allMarkedRead: true),
      ],
      verify: (cubit) {
        expect(markAllRead.calls, 1);
        expect(cubit.state.feed.unreadCount, 0);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'failure leaves the feed untouched',
      build: () {
        markAllRead.result = const Left(NetworkFailure());
        return build();
      },
      seed: () => loaded,
      act: (cubit) => cubit.markAllRead(),
      expect: () => [
        loaded.copyWith(
          failure: const NetworkFailure(),
          failedAction: NotificationsAction.markAllRead,
        ),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'no-op when nothing is unread',
      build: build,
      seed: () => loaded.copyWith(feed: page1.markAllRead()),
      act: (cubit) => cubit.markAllRead(),
      expect: () => <NotificationsState>[],
      verify: (_) => expect(markAllRead.calls, 0),
    );
  });

  group('live', () {
    final live = notification(id: 'live');

    blocTest<NotificationsCubit, NotificationsState>(
      'prepends an incoming notification and bumps the unread counter',
      build: build,
      act: (cubit) async {
        await cubit.load();
        watchLive.emit(live);
      },
      skip: 2,
      expect: () => [loaded.copyWith(feed: page1.prepend(live))],
      verify: (cubit) {
        expect(cubit.state.feed.items.first, live);
        expect(cubit.state.feed.unreadCount, 6);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'a rejected stream is logged, not surfaced',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await watchLive.fail(const UnauthorizedFailure('Sign in'));
      },
      skip: 2,
      expect: () => <NotificationsState>[],
      verify: (cubit) => expect(cubit.state, loaded),
    );

    test('close cancels the live subscription', () async {
      final cubit = build();
      await cubit.load();
      expect(watchLive.controller.hasListener, isTrue);

      await cubit.close();

      expect(watchLive.controller.hasListener, isFalse);
    });
  });
}
