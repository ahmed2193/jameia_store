// B1-14: home's first read starts while the splash plays; the home page
// adopts that cubit (already loaded — no skeleton after the splash) once, and
// every later home page reads afresh.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/features/home/domain/usecases/compose_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/mark_home_popups_shown_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/select_due_home_popups_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_bootstrap_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_launch_prefetch.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_state.dart';

import 'home_test_fakes.dart';

void main() {
  late FakeHomeRepository repository;
  late List<HomeCubit> built;
  late HomeLaunchPrefetch prefetch;

  HomeCubit create() {
    final cubit = HomeCubit(
      WatchHomeFeedUseCase(repository),
      const ComposeHomeFeedUseCase(),
      WatchHomeBootstrapUseCase(repository),
      SelectDueHomePopupsUseCase(repository),
      MarkHomePopupsShownUseCase(repository),
      now: () => DateTime(2026, 9, 29, 10),
    );
    built.add(cubit);
    return cubit;
  }

  setUp(() {
    repository = FakeHomeRepository()..feed = Right(feedOf('launch'));
    built = <HomeCubit>[];
    prefetch = HomeLaunchPrefetch(create);
  });

  tearDown(() async {
    for (final cubit in built) {
      if (!cubit.isClosed) await cubit.close();
    }
  });

  test('the read starts at once, and the page adopts it already loaded — no '
      'skeleton after the splash', () async {
    prefetch.start();
    expect(repository.feedReads, [false], reason: 'reading during the intro');

    await pumpEventQueue();
    final adopted = prefetch.adopt();

    expect(adopted, same(built.single));
    expect(adopted.state.status, LoadPhase.loaded);
    expect(adopted.state.feed.slides.single.id, 'launch');
    expect(repository.feedReads, [false], reason: 'no second read');
  });

  test('adopted mid-read, the page follows the same read', () async {
    prefetch.start();
    final adopted = prefetch.adopt();
    final states = <HomeState>[];
    final sub = adopted.stream.listen(states.add);

    await pumpEventQueue();
    await sub.cancel();

    expect(adopted.state.status, LoadPhase.loaded);
    expect(repository.feedReads, hasLength(1));
  });

  test('without a prefetch the page builds a fresh cubit, loading', () {
    final cubit = prefetch.adopt();

    expect(built, [cubit]);
    expect(cubit.state.status, LoadPhase.loading);
    expect(repository.feedReads, [false]);
  });

  test('handed over once: a later home page reads afresh, and a late start '
      'does nothing', () async {
    prefetch.start();
    final first = prefetch.adopt();
    prefetch.start();
    final second = prefetch.adopt();

    expect(second, isNot(same(first)));
    expect(built, hasLength(2));
    expect(repository.feedReads, hasLength(2));
  });

  test('a second start while one read runs is ignored', () {
    prefetch
      ..start()
      ..start();

    expect(built, hasLength(1));
    expect(repository.feedReads, hasLength(1));
  });

  test('a closed early cubit is never handed over', () async {
    prefetch.start();
    await built.single.close();

    final cubit = prefetch.adopt();

    expect(cubit, isNot(same(built.first)));
    expect(cubit.isClosed, isFalse);
  });
}
