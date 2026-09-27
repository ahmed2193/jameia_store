// HomeCubit + the popup use cases, over the offline screen contract: a saved
// copy paints at once (no skeleton) and the server's replaces it; offline
// with a copy the copy stays (stale, transient failure, no error screen);
// with nothing saved a network failure is the full-screen state and keeps
// its reason; the bootstrap is secondary and its saved copy never offers
// popups; refresh / reconnect force the server; a replaced read's late
// snapshot is dropped; popup frequency (once per session, once per day).
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/compose_home_feed_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/mark_home_popups_shown_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/select_due_home_popups_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/watch_home_bootstrap_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/watch_home_feed_usecase.dart';
import 'package:jameia_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:jameia_mart/src/features/home/presentation/cubit/home_state.dart';

import 'home_test_fakes.dart';

final DateTime _today = DateTime(2026, 9, 17, 10);

void main() {
  late FakeHomeRepository repository;

  HomeCubit buildCubit({WatchHomeFeedUseCase? watchFeed}) => HomeCubit(
    watchFeed ?? WatchHomeFeedUseCase(repository),
    const ComposeHomeFeedUseCase(),
    WatchHomeBootstrapUseCase(repository),
    SelectDueHomePopupsUseCase(repository),
    MarkHomePopupsShownUseCase(repository),
    now: () => _today,
  );

  /// Runs [act] and returns every state it emitted.
  Future<List<HomeState>> record(
    HomeCubit cubit,
    Future<void> Function() act,
  ) async {
    final states = <HomeState>[];
    final sub = cubit.stream.listen(states.add);
    await act();
    await pumpEventQueue();
    await sub.cancel();
    return states;
  }

  setUp(() => repository = FakeHomeRepository());

  group('load', () {
    test('no copy: the skeleton stays until the server answers', () async {
      repository.bootstrap = const Right(
        HomeBootstrap(storeName: 'Jm3eia', popups: [sessionPopup]),
      );
      final cubit = buildCubit();
      final states = await record(cubit, cubit.load);

      expect(states.first.status, isNot(HomeStatus.loading));
      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.feed.slides.single.id, 's1');
      expect(cubit.state.bootstrap.storeName, 'Jm3eia');
      expect(cubit.state.duePopups, [sessionPopup]);
      expect(cubit.state.freshness.fromCache, isFalse);
      expect(cubit.state.freshness.fetchedAt, fetchedAtTime);
      await cubit.close();
    });

    test('a saved copy paints at once, then the server replaces it', () async {
      repository
        ..cachedFeed = feedOf('saved')
        ..feed = Right(feedOf('fresh'));
      final cubit = buildCubit();
      final feeds = (await record(cubit, cubit.load))
          .where((s) => s.isLoaded)
          .map((s) => (s.feed.slides.single.id, s.freshness.fromCache))
          .toSet()
          .toList();

      expect(feeds, [('saved', true), ('fresh', false)]);
      expect(cubit.state.freshness.isStale, isFalse);
      await cubit.close();
    });

    test(
      'offline with a copy: the copy stays, stale, no error screen',
      () async {
        repository
          ..cachedFeed = feedOf('saved')
          ..feed = const Left(NetworkFailure());
        final cubit = buildCubit();
        final states = await record(cubit, cubit.load);

        expect(states.every((s) => s.status != HomeStatus.error), isTrue);
        expect(cubit.state.feed.slides.single.id, 'saved');
        expect(cubit.state.freshness.isStale, isTrue);
        expect(cubit.state.freshness.refreshFailed, isTrue);
        expect(
          states.any((s) => s.isLoaded && s.failure is NetworkFailure),
          isTrue,
          reason: 'a transient failure for the page to decide on',
        );
        await cubit.close();
      },
    );

    test('nothing saved + offline: the full-screen state keeps its reason '
        'while the bootstrap lands; retry recovers', () async {
      repository
        ..feed = const Left(NetworkFailure())
        ..bootstrap = const Right(HomeBootstrap(storeName: 'Jm3eia'));
      final cubit = buildCubit();
      await record(cubit, cubit.load);

      expect(cubit.state.status, HomeStatus.error);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.bootstrap.storeName, 'Jm3eia');

      repository.feed = Right(feedOf('s2'));
      final retry = await record(cubit, cubit.load);
      expect(retry.first.status, HomeStatus.loading);
      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a failed bootstrap never blanks home', () async {
      repository.bootstrap = const Left(ServerFailure('init down'));
      final cubit = buildCubit();
      await record(cubit, cubit.load);

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.bootstrap, HomeBootstrap.empty);
      await cubit.close();
    });

    test('a saved bootstrap never offers the time-boxed popups', () async {
      repository
        ..cachedBootstrap = const HomeBootstrap(popups: [sessionPopup])
        ..bootstrap = const Left(NetworkFailure());
      final cubit = buildCubit();
      await record(cubit, cubit.load);

      expect(cubit.state.bootstrap.popups, [sessionPopup]);
      expect(cubit.state.duePopups, isEmpty);
      expect(cubit.state.hasPendingPopups, isFalse);
      await cubit.close();
    });
  });

  group('refresh + reconnect', () {
    test(
      'a failed refresh keeps the feed and surfaces a transient failure',
      () async {
        final cubit = buildCubit();
        await record(cubit, cubit.load);
        repository.feed = const Left(TimeoutFailure('slow'));
        final states = await record(cubit, cubit.refresh);

        expect(states.every((s) => s.isLoaded), isTrue);
        expect(cubit.state.feed.slides.single.id, 's1');
        expect(states.any((s) => s.failure is TimeoutFailure), isTrue);
        expect(cubit.state.freshness.refreshFailed, isTrue);
        expect(repository.feedReads, [
          false,
          true,
        ], reason: 'refresh is forced');
        await cubit.close();
      },
    );

    test('reconnect refreshes a stale home once, a fresh one never', () async {
      repository
        ..cachedFeed = feedOf('saved')
        ..feed = const Left(NetworkFailure());
      final cubit = buildCubit();
      await record(cubit, cubit.load);
      expect(cubit.state.freshness.isStale, isTrue);

      repository.feed = Right(feedOf('back'));
      await Future.wait([cubit.onReconnected(), cubit.onReconnected()]);
      expect(repository.feedReads, [false, true], reason: 'single-flight');
      expect(cubit.state.feed.slides.single.id, 'back');
      expect(cubit.state.freshness.isStale, isFalse);

      await cubit.onReconnected();
      expect(repository.feedReads, [false, true], reason: 'fresh: nothing');
      await cubit.close();
    });

    test('equal data from the server only changes the freshness', () async {
      repository
        ..cachedFeed = feedOf('same')
        ..feed = Right(feedOf('same'));
      final cubit = buildCubit();
      final states = await record(cubit, cubit.load);
      final loaded = states.where((s) => s.isLoaded).toList();

      expect(loaded.map((s) => s.feed).toSet(), hasLength(1));
      expect(loaded.first.freshness.fromCache, isTrue);
      expect(loaded.last.freshness.fromCache, isFalse);
      await cubit.close();
    });

    test('a replaced read never delivers its late snapshot', () async {
      final gate = GatedWatchHomeFeed();
      final cubit = buildCubit(watchFeed: gate);

      unawaited(cubit.load());
      final refreshed = cubit.refresh();
      gate.reads[1].add(networkFeed('new'));
      await gate.reads[1].close();
      await refreshed;
      // The first read's slow disk copy lands after the refresh answered.
      gate.reads[0].add(cachedFeedSnapshot('old'));
      await pumpEventQueue();

      expect(cubit.state.feed.slides.single.id, 'new');
      await cubit.close();
    });

    test('no emit after close', () async {
      final gate = GatedWatchHomeFeed();
      final cubit = buildCubit(watchFeed: gate);

      final pending = cubit.load();
      await cubit.close();
      gate.reads.single.add(networkFeed('late'));

      await expectLater(pending, completes);
      expect(cubit.state.isLoaded, isFalse);
    });
  });

  group('popups', () {
    test('the queue shows once per session; day popups are stamped', () async {
      repository.bootstrap = const Right(
        HomeBootstrap(popups: [sessionPopup, dailyPopup]),
      );
      final cubit = buildCubit();
      await record(cubit, cubit.load);
      expect(cubit.state.hasPendingPopups, isTrue);
      expect(cubit.state.duePopups, [sessionPopup, dailyPopup]);

      cubit.markPopupsShown();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.hasPendingPopups, isFalse);
      expect(cubit.state.popupsShown, isTrue);
      expect(repository.shownDays, {'p-day': '2026-09-17'});

      await record(cubit, cubit.refresh);
      expect(cubit.state.duePopups, isEmpty);
      await cubit.close();
    });

    test('a day popup already shown today is not due; tomorrow it is', () {
      repository.shownDays['p-day'] = '2026-09-17';
      final select = SelectDueHomePopupsUseCase(repository);
      const popups = [sessionPopup, dailyPopup];

      final today = select(
        SelectDueHomePopupsParams(popups: popups, today: _today),
      );
      final tomorrow = select(
        SelectDueHomePopupsParams(
          popups: popups,
          today: _today.add(const Duration(days: 1)),
        ),
      );

      expect(today.getOrElse(() => const []), [sessionPopup]);
      expect(tomorrow.getOrElse(() => const []), popups);
    });

    test('an unreadable stamp counts as "not shown"', () {
      repository.stampReadFailure = const CacheFailure('prefs');
      final due = SelectDueHomePopupsUseCase(repository)(
        SelectDueHomePopupsParams(popups: const [dailyPopup], today: _today),
      );

      expect(due.getOrElse(() => const []), [dailyPopup]);
    });

    test('marking reports the first stamp failure', () async {
      repository.stampWriteFailure = const CacheFailure('disk full');
      final result = await MarkHomePopupsShownUseCase(repository)(
        MarkHomePopupsShownParams(
          popups: const [sessionPopup, dailyPopup],
          today: _today,
        ),
      );

      expect(result.isLeft(), isTrue);
    });

    test('dayStamp pads month and day', () {
      expect(
        SelectDueHomePopupsUseCase.dayStamp(DateTime(2026, 1, 5)),
        '2026-01-05',
      );
    });
  });
}
