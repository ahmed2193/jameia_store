// HomeCubit + the popup use cases: load / refresh, the secondary bootstrap,
// stale replies, and popup frequency (once per session, once per day).
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/get_home_bootstrap_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/compose_home_feed_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/get_home_feed_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/mark_home_popups_shown_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/select_due_home_popups_usecase.dart';
import 'package:jameia_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:jameia_mart/src/features/home/presentation/cubit/home_state.dart';

import 'home_test_fakes.dart';

final DateTime _today = DateTime(2026, 9, 17, 10);

void main() {
  late FakeHomeRepository repository;

  HomeCubit buildCubit({
    GetHomeFeedUseCase? getFeed,
    GetHomeBootstrapUseCase? getBootstrap,
    DateTime Function()? now,
  }) => HomeCubit(
    getFeed ?? GetHomeFeedUseCase(repository),
    const ComposeHomeFeedUseCase(),
    getBootstrap ?? GetHomeBootstrapUseCase(repository),
    SelectDueHomePopupsUseCase(repository),
    MarkHomePopupsShownUseCase(repository),
    now: now ?? () => _today,
  );

  setUp(() => repository = FakeHomeRepository());

  group('load', () {
    blocTest<HomeCubit, HomeState>(
      'skeleton, then ONE loaded emit carrying feed + bootstrap + due popups',
      setUp: () => repository.bootstrap = const Right(
        HomeBootstrap(storeName: 'Jm3eia', popups: [sessionPopup]),
      ),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loaded)
            .having((s) => s.feed.slides.single.id, 'slide', 's1')
            .having((s) => s.bootstrap.storeName, 'store', 'Jm3eia')
            .having((s) => s.duePopups, 'due', [sessionPopup])
            .having((s) => s.failure, 'failure', isNull),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'a failed first load is the full-screen error; retry recovers',
      setUp: () => repository.feed = const Left(NetworkFailure('offline')),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        repository.feed = Right(feedOf('s2'));
        await cubit.load();
      },
      expect: () => [
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.error)
            .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loaded)
            .having((s) => s.feed.slides.single.id, 'slide', 's2'),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'a failed bootstrap never blanks home',
      setUp: () =>
          repository.bootstrap = const Left(ServerFailure('init down')),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loaded)
            .having((s) => s.bootstrap, 'bootstrap', HomeBootstrap.empty)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );
  });

  group('refresh', () {
    blocTest<HomeCubit, HomeState>(
      'a failed refresh keeps the feed and surfaces a transient failure',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        repository.feed = const Left(TimeoutFailure('slow'));
        await cubit.refresh();
      },
      skip: 2,
      expect: () => [
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loaded)
            .having((s) => s.feed.slides.single.id, 'slide', 's1')
            .having((s) => s.failure, 'failure', isA<TimeoutFailure>()),
      ],
    );

    test(
      'a slow reply of an older load never overwrites a newer one',
      () async {
        final gate = GatedGetHomeFeed();
        final cubit = buildCubit(
          getFeed: gate,
          getBootstrap: StubGetHomeBootstrap(const Right(HomeBootstrap.empty)),
        );

        final first = cubit.load();
        final second = cubit.refresh();
        gate.calls[1].complete(Right(feedOf('new')));
        await second;
        gate.calls[0].complete(Right(feedOf('old')));
        await first;

        expect(cubit.state.feed.slides.single.id, 'new');
        await cubit.close();
      },
    );

    test('no emit after close', () async {
      final gate = GatedGetHomeFeed();
      final cubit = buildCubit(
        getFeed: gate,
        getBootstrap: StubGetHomeBootstrap(const Right(HomeBootstrap.empty)),
      );

      final pending = cubit.load();
      await cubit.close();
      gate.calls.single.complete(Right(feedOf('late')));

      await expectLater(pending, completes);
    });
  });

  group('popups', () {
    test('the queue shows once per session; day popups are stamped', () async {
      repository.bootstrap = const Right(
        HomeBootstrap(popups: [sessionPopup, dailyPopup]),
      );
      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.hasPendingPopups, isTrue);
      expect(cubit.state.duePopups, [sessionPopup, dailyPopup]);

      cubit.markPopupsShown();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.hasPendingPopups, isFalse);
      expect(cubit.state.popupsShown, isTrue);
      expect(repository.shownDays, {'p-day': '2026-09-17'});

      await cubit.refresh();
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
