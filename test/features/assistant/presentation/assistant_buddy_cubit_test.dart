// The buddy's timing: the greeting waits for a touch, a dwell on a screen
// that may greet and a quiet moment without scrolling; it comes once per
// shell and only on days the policy allows; the launcher steps aside while
// scrolling down and comes back on another tab; the outcomes are recorded;
// a newcomer is invited to the tour, which the launcher makes way for and
// hands back from with a hop and a short "I'm right here". The launcher's
// thoughts open every visit with a greeting and one more line in the same
// bubble, then come one at a time — a new topic each, further apart every
// few, resting after a visit's worth; they play their whole line, keep the
// launcher out while scrolling, hold the greeting back until said, wait
// behind the chat and, back from it, ask if there is anything else.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_nudge_log.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_nudge_outcome.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_buddy_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_buddy_scene.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_thought.dart';

import 'assistant_nudge_fakes.dart';

void main() {
  const home = AssistantBuddyScene(
    place: 'home',
    available: true,
    greetHere: true,
    launcherHere: true,
  );
  const search = AssistantBuddyScene(
    place: 'search',
    available: true,
    launcherHere: true,
  );

  late InMemoryAssistantNudgeRepository repository;
  late DateTime now;
  late AssistantBuddyCubit cubit;

  Future<void> wait([int ms = 80]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() async {
    repository = InMemoryAssistantNudgeRepository.met();
    now = DateTime(2026, 9, 27, 20);
    cubit = buddyCubit(repository, clock: () => now);
    await cubit.start();
  });

  tearDown(() => cubit.close());

  test('the launcher shows once the log is read and the store has it', () {
    expect(cubit.state.launcherHidden, isFalse);
    expect(cubit.state.launcherShown, isFalse);
    cubit.setScene(home);
    expect(cubit.state.launcherShown, isTrue);
  });

  test('a launcher hidden for today stays hidden', () async {
    repository.log = AssistantNudgeLog(
      launcherHiddenUntil: DateTime(2026, 9, 28),
    );
    final hidden = buddyCubit(repository, clock: () => now);
    addTearDown(hidden.close);
    await hidden.start();
    hidden.setScene(home);
    expect(hidden.state.launcherShown, isFalse);
  });

  test('no greeting before the customer touches anything', () async {
    cubit.setScene(home);
    await wait();
    expect(cubit.state.nudge, isNull);
    cubit.touched();
    await wait();
    expect(cubit.state.nudge, isNotNull);
    expect(cubit.state.launcherShown, isFalse); // the greeting took over
    expect(repository.log.lastShownAt, now);
  });

  test('scrolling postpones the greeting until it has been quiet', () async {
    cubit
      ..setScene(home)
      ..scrollStarted(towardsEnd: true);
    await wait();
    expect(cubit.state.nudge, isNull, reason: 'still scrolling');
    cubit.scrollStopped();
    await wait(5);
    expect(cubit.state.nudge, isNull, reason: 'not quiet yet');
    await wait();
    expect(cubit.state.nudge, isNotNull);
  });

  test('no greeting on a screen that does not greet', () async {
    cubit
      ..setScene(search)
      ..touched();
    await wait();
    expect(cubit.state.nudge, isNull);
  });

  test('leaving before the dwell cancels it', () async {
    cubit
      ..setScene(home)
      ..touched()
      ..setScene(search);
    await wait();
    expect(cubit.state.nudge, isNull);
    expect(repository.writes, 0);
  });

  test('a dialog over the shell holds the greeting back', () async {
    cubit
      ..setScene(home)
      ..touched()
      ..setScene(
        const AssistantBuddyScene(
          place: 'home',
          available: true,
          greetHere: true,
          launcherHere: true,
          inFront: false,
        ),
      );
    await wait();
    expect(cubit.state.nudge, isNull);
  });

  test('a day that already had its greeting stays quiet', () async {
    repository.log = AssistantNudgeLog(lastShownAt: DateTime(2026, 9, 27, 9));
    cubit
      ..setScene(home)
      ..touched();
    await wait();
    expect(cubit.state.nudge, isNull);
  });

  test('opening the chat from the launcher means no greeting', () async {
    cubit
      ..setScene(home)
      ..touched();
    await cubit.launcherOpened();
    await wait();
    expect(cubit.state.nudge, isNull);
    expect(repository.log.lastOpenedAt, now);
  });

  test('closing the greeting records it and the launcher hops back', () async {
    cubit
      ..setScene(home)
      ..touched();
    await wait();
    final cheers = cubit.state.cheers;
    await cubit.greetingClosed(AssistantNudgeOutcome.dismissed);
    expect(cubit.state.nudge, isNull);
    expect(cubit.state.cheers, cheers + 1);
    expect(cubit.state.launcherShown, isTrue);
    expect(repository.log.snoozedUntil, now.add(const Duration(days: 3)));
  });

  test('the greeting comes once per shell', () async {
    cubit
      ..setScene(home)
      ..touched();
    await wait();
    await cubit.greetingClosed(AssistantNudgeOutcome.ignored);
    now = now.add(const Duration(days: 1));
    cubit
      ..setScene(search)
      ..setScene(home);
    await wait();
    expect(cubit.state.nudge, isNull);
  });

  test('scrolling down tucks the launcher away; up or a new tab brings it '
      'back', () {
    cubit
      ..setScene(home)
      ..scrollStarted(towardsEnd: true);
    expect(cubit.state.launcherShown, isFalse);
    cubit.scrollStarted(towardsEnd: false);
    expect(cubit.state.launcherShown, isTrue);
    cubit.scrollStarted(towardsEnd: true);
    cubit.setScene(search);
    expect(cubit.state.launcherShown, isTrue);
  });

  test('with a screen reader the launcher never tucks away', () {
    cubit
      ..setScene(
        const AssistantBuddyScene(
          place: 'home',
          available: true,
          launcherHere: true,
          screenReader: true,
        ),
      )
      ..scrollStarted(towardsEnd: true);
    expect(cubit.state.launcherShown, isTrue);
  });

  test('the keyboard hides the launcher', () {
    cubit.setScene(
      const AssistantBuddyScene(
        place: 'search',
        available: true,
        launcherHere: true,
        keyboardOpen: true,
      ),
    );
    expect(cubit.state.launcherShown, isFalse);
  });

  test('a cart add makes a shown mascot hop, never a hidden one', () {
    cubit.cheer();
    expect(cubit.state.cheers, 0);
    cubit
      ..setScene(home)
      ..cheer();
    expect(cubit.state.cheers, 1);
  });

  test('"hide for today" hides at once and is remembered', () async {
    cubit.setScene(home);
    await cubit.hideLauncher();
    expect(cubit.state.launcherShown, isFalse);
    expect(repository.log.launcherHiddenUntil, DateTime(2026, 9, 28));
  });

  group('the tour', () {
    test('a newcomer is known once the log is read and invited', () async {
      final newcomer = buddyCubit(
        InMemoryAssistantNudgeRepository(),
        clock: () => now,
      );
      addTearDown(newcomer.close);
      expect(newcomer.state.onboarded, isTrue, reason: 'unknown yet');
      await newcomer.start();
      expect(newcomer.state.onboarded, isFalse);
      newcomer
        ..setScene(home)
        ..touched();
      await wait();
      expect(newcomer.state.nudge?.invitesTour, isTrue);
    });

    test('an unreadable log never forces the tour', () async {
      final broken = InMemoryAssistantNudgeRepository()
        ..readFailure = const CacheFailure('broken');
      final cubit = buddyCubit(broken, clock: () => now);
      addTearDown(cubit.close);
      await cubit.start();
      expect(cubit.state.onboarded, isTrue);
      expect(cubit.state.launcherHidden, isFalse);
    });

    test('the launcher makes way, the meeting is remembered and no greeting '
        'follows', () async {
      final newcomer = InMemoryAssistantNudgeRepository();
      final cubit = buddyCubit(newcomer, clock: () => now);
      addTearDown(cubit.close);
      await cubit.start();
      cubit
        ..setScene(home)
        ..touched();
      await cubit.tourStarted();
      expect(cubit.state.touring, isTrue);
      expect(cubit.state.onboarded, isTrue);
      expect(cubit.state.launcherShown, isFalse);
      expect(newcomer.log.onboardedAt, now);
      await wait();
      expect(cubit.state.nudge, isNull);
    });

    test(
      'it hands back with a hop and thinks where the launcher lives',
      () async {
        cubit.setScene(home);
        await cubit.tourStarted();
        final cheers = cubit.state.cheers;
        cubit.tourEnded(coach: true);
        expect(cubit.state.touring, isFalse);
        expect(cubit.state.cheers, cheers + 1);
        expect(cubit.state.thought, AssistantThought.coach);
        expect(cubit.state.launcherShown, isTrue);
        cubit.thoughtSaid(AssistantThought.coach);
        expect(cubit.state.thought, AssistantThought.coach, reason: 'alone');
        cubit.thoughtDone(AssistantThought.coach);
        expect(cubit.state.thought, isNull);
      },
    );

    test('a touch lets the coach finish its line', () async {
      cubit.setScene(home);
      await cubit.tourStarted();
      cubit.tourEnded(coach: true);
      cubit.touched();
      expect(cubit.state.thought, AssistantThought.coach);
    });

    test('off to the chat: no coach', () async {
      cubit.setScene(home);
      await cubit.tourStarted();
      cubit.tourEnded(coach: false);
      expect(cubit.state.thought, isNull);
      expect(cubit.state.touring, isFalse);
    });
  });

  group('the thoughts', () {
    late AssistantBuddyCubit thinker;

    Future<AssistantBuddyCubit> thinking({
      AssistantNudgeLog? log,
      Duration every = const Duration(days: 1),
      int seed = 1,
    }) async {
      if (log != null) repository.log = log;
      final created = buddyCubit(
        repository,
        clock: () => now,
        thinkAfter: const Duration(milliseconds: 40),
        thinkEvery: every,
        random: Random(seed),
      );
      await created.start();
      return created;
    }

    tearDown(() => thinker.close());

    test('a visit opens with a greeting once the launcher has been on screen '
        'a moment, with nothing written to the device', () async {
      thinker = await thinking();
      thinker.setScene(search);
      expect(thinker.state.thought, isNull, reason: 'not on arrival');
      await wait();
      expect(thinker.state.thought?.opens, isTrue);
      expect(repository.writes, 0);
    });

    test('a first meeting opens with the hello', () async {
      thinker = await thinking(log: AssistantNudgeLog.empty);
      thinker.setScene(search);
      await wait();
      expect(thinker.state.thought, AssistantThought.hello);
    });

    test('every opening of the app greets — also on a day the greeting '
        'keeps quiet', () async {
      final quiet = AssistantNudgeLog.empty
          .onboarded(DateTime(2026))
          .record(AssistantNudgeOutcome.dismissed, now);
      for (var opening = 0; opening < 3; opening++) {
        thinker = await thinking(log: quiet, seed: opening);
        thinker.setScene(search);
        await wait();
        expect(thinker.state.thought?.opens, isTrue);
        await thinker.close();
      }
      thinker = await thinking();
    });

    test('the greeting hands over to one more line in the same bubble, then '
        'it rests', () async {
      thinker = await thinking();
      thinker.setScene(search);
      await wait();
      final opener = thinker.state.thought!;
      thinker.thoughtSaid(opener);
      final second = thinker.state.thought;
      expect(second, isNotNull, reason: 'handed over at once');
      expect(second!.opens, isFalse);
      thinker.thoughtSaid(second);
      expect(thinker.state.thought, second, reason: 'nothing follows it');
      thinker.thoughtDone(second);
      expect(thinker.state.thought, isNull);
      await wait();
      expect(thinker.state.thought, isNull, reason: 'the next waits its turn');
    });

    test('a touch lets the line finish', () async {
      thinker = await thinking();
      thinker.setScene(search);
      await wait();
      final line = thinker.state.thought;
      thinker.touched();
      expect(thinker.state.thought, line);
    });

    test('later lines come one at a time, a new topic each, further apart '
        'every few', () async {
      thinker = await thinking(every: const Duration(milliseconds: 100));
      thinker.setScene(search);
      await wait();
      final said = <AssistantThought>[thinker.state.thought!];
      thinker.thoughtSaid(said.last);
      said.add(thinker.state.thought!);
      for (
        var session = 2;
        session <= AssistantBuddyCubit.sessionsPerRound;
        session++
      ) {
        thinker
          ..thoughtSaid(said.last)
          ..thoughtDone(said.last);
        expect(thinker.state.thought, isNull, reason: 'a pause between');
        await wait(50);
        expect(thinker.state.thought, isNull, reason: 'not yet');
        await wait(150);
        said.add(thinker.state.thought!);
        expect(said.last.opens, isFalse);
      }
      for (var i = 1; i < said.length; i++) {
        expect(said[i].topic, isNot(said[i - 1].topic));
      }
      expect(said.toSet(), hasLength(said.length), reason: 'no repeats');
      // A stretch said: twice the pause now (200 ms here).
      thinker
        ..thoughtSaid(said.last)
        ..thoughtDone(said.last);
      await wait(150);
      expect(thinker.state.thought, isNull, reason: 'a longer pause');
      await wait(150);
      expect(thinker.state.thought, isNotNull);
    });

    test('scrolling down keeps the launcher until its line is said — and '
        'then no second line', () async {
      thinker = await thinking();
      thinker.setScene(search);
      await wait();
      final opener = thinker.state.thought!;
      thinker.scrollStarted(towardsEnd: true);
      expect(thinker.state.launcherShown, isTrue);
      thinker
        ..scrollStopped()
        ..thoughtSaid(opener);
      expect(thinker.state.thought, opener, reason: 'no hand-over');
      thinker.thoughtDone(opener);
      expect(thinker.state.launcherShown, isFalse, reason: 'now it tucks away');
    });

    test('the greeting waits for the lines to be said', () async {
      thinker = await thinking();
      thinker.setScene(home);
      await wait();
      final opener = thinker.state.thought!;
      thinker.touched();
      await wait();
      expect(thinker.state.nudge, isNull, reason: 'the lines come first');
      thinker.thoughtSaid(opener);
      final second = thinker.state.thought!;
      thinker
        ..thoughtSaid(second)
        ..thoughtDone(second);
      await wait();
      expect(thinker.state.nudge, isNotNull);
      expect(thinker.state.thought, isNull);
    });

    test('back after a while is a new visit: it greets again; a quick look '
        'away is not', () async {
      thinker = await thinking();
      thinker.setScene(search);
      await wait();
      thinker.thoughtDone(thinker.state.thought!);

      thinker.appPaused();
      now = now.add(const Duration(seconds: 10));
      thinker.appResumed();
      await wait();
      expect(thinker.state.thought, isNull, reason: 'the same visit');

      thinker.appPaused();
      now = now.add(AssistantBuddyCubit.defaultVisitGap);
      thinker.appResumed();
      expect(thinker.state.thought, isNull, reason: 'not on arrival');
      await wait();
      expect(thinker.state.thought?.opens, isTrue);
    });

    test('nothing starts while the app is away; a line left over from an '
        'earlier visit goes', () async {
      thinker = await thinking();
      thinker
        ..setScene(search)
        ..appPaused();
      await wait();
      expect(thinker.state.thought, isNull, reason: 'nobody sees it');

      thinker.appResumed();
      await wait();
      expect(thinker.state.thought?.opens, isTrue);
      thinker.appPaused();
      now = now.add(const Duration(hours: 2));
      thinker.appResumed();
      expect(thinker.state.thought, isNull);
      await wait();
      expect(thinker.state.thought?.opens, isTrue);
    });

    test('never with a screen reader, nor while scrolling', () async {
      thinker = await thinking();
      thinker.setScene(
        const AssistantBuddyScene(
          place: 'search',
          available: true,
          launcherHere: true,
          screenReader: true,
        ),
      );
      await wait();
      expect(thinker.state.thought, isNull);
      await thinker.close();

      thinker = await thinking();
      thinker
        ..setScene(search)
        ..scrollStarted(towardsEnd: false);
      await wait();
      expect(thinker.state.thought, isNull, reason: 'still scrolling');
      thinker.scrollStopped();
      await wait();
      expect(thinker.state.thought?.opens, isTrue);
    });

    test('only the thought that ended goes', () async {
      thinker = await thinking();
      thinker.setScene(search);
      await wait();
      final opener = thinker.state.thought;
      thinker.thoughtDone(AssistantThought.coach);
      thinker.thoughtSaid(AssistantThought.coach);
      expect(thinker.state.thought, opener);
    });

    test('opening the chat answers it; the next line waits for the way '
        'back', () async {
      const underChat = AssistantBuddyScene(
        place: 'search',
        available: true,
        launcherHere: true,
        inFront: false,
      );
      thinker = await thinking(every: const Duration(milliseconds: 60));
      thinker.setScene(search);
      await wait();
      await thinker.launcherOpened();
      expect(thinker.state.thought, isNull);
      thinker.setScene(underChat);
      await wait(150);
      expect(thinker.state.thought, isNull, reason: 'none behind the chat');
      thinker.setScene(search);
      expect(thinker.state.thought, isNull, reason: 'not on the way back');
      await wait(150);
      expect(thinker.state.thought, AssistantThought.anythingElse);

      thinker.thoughtDone(AssistantThought.anythingElse);
      await wait(150);
      final next = thinker.state.thought;
      expect(next, isNotNull);
      expect(next, isNot(AssistantThought.anythingElse), reason: 'once');
      expect(next!.opens, isFalse, reason: 'already greeted');
    });

    test(
      "after a visit's worth of lines it rests until the next visit",
      () async {
        thinker = await thinking(every: const Duration(milliseconds: 10));
        thinker.setScene(search);
        await wait();
        thinker.thoughtDone(thinker.state.thought!);
        for (
          var sessions = 1;
          sessions < AssistantBuddyCubit.maxSessionsPerVisit;
          sessions++
        ) {
          await wait(150);
          final line = thinker.state.thought;
          expect(line, isNotNull, reason: 'line ${sessions + 1}');
          thinker.thoughtDone(line!);
        }
        await wait(300);
        expect(thinker.state.thought, isNull, reason: 'resting');

        thinker.appPaused();
        now = now.add(AssistantBuddyCubit.defaultVisitGap);
        thinker.appResumed();
        await wait();
        expect(thinker.state.thought?.opens, isTrue, reason: 'a new visit');
      },
    );
  });
}
