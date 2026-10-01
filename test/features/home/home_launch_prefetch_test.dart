// B1-14: home's first read starts while the splash plays; the home page
// adopts that cubit (already loaded — no skeleton after the splash) once, and
// every later home page reads afresh.
// Review fixes: B1 — the read waits for the saved language and is never
// handed over in another one; I4 — a read the session's end (or age) made
// stale is closed, never adopted.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/network/locale_provider.dart';
import 'package:hero_mart/src/features/home/domain/usecases/check_first_order_welcome_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/compose_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/mark_home_popups_shown_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/select_due_home_popups_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_bootstrap_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_launch_prefetch.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_state.dart';
import 'package:intl/intl.dart' show Intl;

import 'home_test_fakes.dart';

void main() {
  late FakeHomeRepository repository;
  late List<HomeCubit> built;
  late List<String> readLanguages;
  late String language;
  late DateTime clock;
  late HomeLaunchPrefetch prefetch;

  HomeCubit create() {
    readLanguages.add(language);
    final cubit = HomeCubit(
      WatchHomeFeedUseCase(repository),
      const ComposeHomeFeedUseCase(),
      WatchHomeBootstrapUseCase(repository),
      SelectDueHomePopupsUseCase(repository),
      MarkHomePopupsShownUseCase(repository),
      CheckFirstOrderWelcomeUseCase(repository),
      now: () => DateTime(2026, 9, 29, 10),
    );
    built.add(cubit);
    return cubit;
  }

  setUp(() {
    repository = FakeHomeRepository()..feed = Right(feedOf('launch'));
    built = <HomeCubit>[];
    readLanguages = <String>[];
    language = 'en';
    clock = DateTime(2026, 9, 29, 10);
    prefetch = HomeLaunchPrefetch(
      create,
      language: () => language,
      now: () => clock,
    );
  });

  tearDown(() async {
    for (final cubit in built) {
      if (!cubit.isClosed) await cubit.close();
    }
  });

  test('the read starts at once, and the page adopts it already loaded — no '
      'skeleton after the splash', () async {
    prefetch
      ..localeReady()
      ..start();
    expect(repository.feedReads, [false], reason: 'reading during the intro');

    await pumpEventQueue();
    final adopted = prefetch.adopt();

    expect(adopted, same(built.single));
    expect(adopted.state.status, LoadPhase.loaded);
    expect(adopted.state.feed.slides.single.id, 'launch');
    expect(repository.feedReads, [false], reason: 'no second read');
  });

  test('adopted mid-read, the page follows the same read', () async {
    prefetch
      ..localeReady()
      ..start();
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
    prefetch
      ..localeReady()
      ..start();
    final first = prefetch.adopt();
    prefetch.start();
    final second = prefetch.adopt();

    expect(second, isNot(same(first)));
    expect(built, hasLength(2));
    expect(repository.feedReads, hasLength(2));
  });

  test('a second start while one read runs is ignored', () {
    prefetch
      ..localeReady()
      ..start()
      ..start();

    expect(built, hasLength(1));
    expect(repository.feedReads, hasLength(1));
  });

  test('a closed early cubit is never handed over', () async {
    prefetch
      ..localeReady()
      ..start();
    await built.single.close();

    final cubit = prefetch.adopt();

    expect(cubit, isNot(same(built.first)));
    expect(cubit.isClosed, isFalse);
  });

  group('B1: the saved language first', () {
    test('the launch frame alone (reduced motion fires it in the first '
        'build) reads nothing until the saved language is on', () {
      prefetch.start();
      expect(built, isEmpty, reason: 'the locale restore has not ended');

      language = 'ar';
      prefetch.localeReady();

      expect(readLanguages, ['ar']);
      expect(repository.feedReads, hasLength(1));
    });

    test('the language may land first: the launch frame then reads', () {
      language = 'ar';
      prefetch.localeReady();
      expect(built, isEmpty);

      prefetch.start();

      expect(readLanguages, ['ar']);
    });

    test('a read made in another language is dropped at adopt and read '
        'again', () async {
      prefetch
        ..localeReady()
        ..start();
      await pumpEventQueue();
      final early = built.single;

      language = 'ar';
      final adopted = prefetch.adopt();

      expect(adopted, isNot(same(early)));
      expect(early.isClosed, isTrue);
      expect(readLanguages, ['en', 'ar']);
    });

    test('the language is the one requests carry (Intl.defaultLocale)', () {
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);
      Intl.defaultLocale = 'ar';
      String? sent;
      final real = HomeLaunchPrefetch(() {
        sent = const IntlLocaleProvider().languageCode;
        return create();
      }, language: () => const IntlLocaleProvider().languageCode);

      real
        ..start()
        ..localeReady();

      expect(sent, 'ar');
      expect(real.adopt(), same(built.single), reason: 'same language kept');
    });
  });

  group('I4: a stale launch read is never handed over', () {
    test('the session expired under the splash: the read is closed and the '
        'later page reads afresh', () async {
      prefetch
        ..localeReady()
        ..start();
      await pumpEventQueue();
      final early = built.single;

      prefetch.discard();
      expect(early.isClosed, isTrue);

      final adopted = prefetch.adopt();
      expect(adopted, isNot(same(early)));
      expect(adopted.isClosed, isFalse);
      expect(repository.feedReads, hasLength(2));
    });

    test('a read older than maxHold is dropped at adopt', () async {
      prefetch
        ..localeReady()
        ..start();
      await pumpEventQueue();
      final early = built.single;

      clock = clock.add(
        HomeLaunchPrefetch.maxHold + const Duration(seconds: 1),
      );
      final adopted = prefetch.adopt();

      expect(adopted, isNot(same(early)));
      expect(early.isClosed, isTrue);
    });

    test('a discard after the hand-over leaves the page cubit alone', () {
      prefetch
        ..localeReady()
        ..start();
      final adopted = prefetch.adopt();

      prefetch.discard();

      expect(adopted.isClosed, isFalse);
    });
  });
}
