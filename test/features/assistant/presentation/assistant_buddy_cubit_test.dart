// The buddy's timing: the greeting waits for a touch, a dwell on a screen
// that may greet and a quiet moment without scrolling; it comes once per
// shell and only on days the policy allows; the launcher steps aside while
// scrolling down and comes back on another tab; the outcomes are recorded;
// a newcomer is invited to the tour, which the launcher makes way for and
// hands back from with a hop and a short "I'm right here".
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge_log.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge_outcome.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_buddy_cubit.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_buddy_scene.dart';

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
      'it hands back with a hop and says where the launcher lives',
      () async {
        cubit.setScene(home);
        await cubit.tourStarted();
        final cheers = cubit.state.cheers;
        cubit.tourEnded(coach: true);
        expect(cubit.state.touring, isFalse);
        expect(cubit.state.cheers, cheers + 1);
        expect(cubit.state.coaching, isTrue);
        expect(cubit.state.launcherShown, isTrue);
        await wait(120);
        expect(cubit.state.coaching, isFalse, reason: 'it goes by itself');
      },
    );

    test('a touch ends the coach early', () async {
      cubit.setScene(home);
      await cubit.tourStarted();
      cubit.tourEnded(coach: true);
      cubit.touched();
      expect(cubit.state.coaching, isFalse);
    });

    test('off to the chat: no coach', () async {
      cubit.setScene(home);
      await cubit.tourStarted();
      cubit.tourEnded(coach: false);
      expect(cubit.state.coaching, isFalse);
      expect(cubit.state.touring, isFalse);
    });
  });
}
