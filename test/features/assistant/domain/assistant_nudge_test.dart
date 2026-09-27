// The assistant greeting's rules: when it may come (one a day, none on a
// day the chat was opened, quiet after "not now" or repeated ignores), what
// it says for the moment, the first meeting that offers the tour, and the
// use cases that read and write its log.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_day_part.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge_log.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge_outcome.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge_policy.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_onboarding_step.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_starter.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/claim_assistant_nudge_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/complete_assistant_onboarding_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/get_assistant_launcher_hidden_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/get_assistant_onboarded_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/hide_assistant_launcher_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/record_assistant_nudge_outcome_usecase.dart';

import '../presentation/assistant_nudge_fakes.dart';

void main() {
  const policy = AssistantNudgePolicy();
  final morning = DateTime(2026, 9, 27, 9);
  final evening = DateTime(2026, 9, 27, 20);
  final nextMorning = DateTime(2026, 9, 28, 9);

  group('AssistantNudgePolicy', () {
    test('a fresh install may be greeted', () {
      expect(policy.allows(AssistantNudgeLog.empty, morning), isTrue);
    });

    test('one greeting a day', () {
      final log = AssistantNudgeLog.empty.shownAt(morning);
      expect(policy.allows(log, evening), isFalse);
      expect(policy.allows(log, nextMorning), isTrue);
    });

    test('none on a day the chat was opened', () {
      final log = AssistantNudgeLog.empty.record(
        AssistantNudgeOutcome.opened,
        morning,
      );
      expect(policy.allows(log, evening), isFalse);
      expect(policy.allows(log, nextMorning), isTrue);
    });

    test('"not now" keeps it quiet for three days', () {
      final log = AssistantNudgeLog.empty.record(
        AssistantNudgeOutcome.dismissed,
        morning,
      );
      expect(log.snoozedUntil, morning.add(const Duration(days: 3)));
      expect(policy.allows(log, morning.add(const Duration(days: 2))), isFalse);
      expect(policy.allows(log, morning.add(const Duration(days: 3))), isTrue);
    });

    test('two ignored greetings in a row back it off for a week', () {
      final once = AssistantNudgeLog.empty.record(
        AssistantNudgeOutcome.ignored,
        morning,
      );
      expect(once.ignoredInARow, 1);
      expect(once.snoozedUntil, isNull);
      expect(policy.allows(once, nextMorning), isTrue);

      final twice = once.record(AssistantNudgeOutcome.ignored, nextMorning);
      expect(twice.ignoredInARow, 0);
      expect(twice.snoozedUntil, nextMorning.add(const Duration(days: 7)));
    });

    test('opening the chat resets the ignored streak', () {
      final log = AssistantNudgeLog.empty
          .record(AssistantNudgeOutcome.ignored, morning)
          .record(AssistantNudgeOutcome.opened, evening);
      expect(log.ignoredInARow, 0);
    });

    test('"hide for today" lasts until the next local midnight', () {
      final until = AssistantNudgePolicy.endOfDay(evening);
      expect(until, DateTime(2026, 9, 28));
      final log = AssistantNudgeLog.empty.hideLauncherUntil(until);
      expect(log.isLauncherHiddenAt(evening), isTrue);
      expect(log.isLauncherHiddenAt(nextMorning), isFalse);
    });
  });

  group('AssistantNudge.compose', () {
    test('a cart with items leads with finishing it', () {
      final nudge = AssistantNudge.compose(at: morning, hasCartItems: true);
      expect(nudge.message, AssistantNudgeMessage.cart);
      expect(nudge.starters.first, AssistantStarter.completeCart);
      expect(nudge.starters, hasLength(AssistantNudge.starterCount));
    });

    test('the meal of the moment otherwise', () {
      final breakfast = AssistantNudge.compose(
        at: morning,
        hasCartItems: false,
      );
      expect(breakfast.dayPart, AssistantDayPart.morning);
      expect(breakfast.message, AssistantNudgeMessage.morning);
      expect(breakfast.starters.first, AssistantStarter.breakfast);

      final dinner = AssistantNudge.compose(at: evening, hasCartItems: false);
      expect(dinner.message, AssistantNudgeMessage.evening);
      expect(dinner.starters.first, AssistantStarter.dinner);

      final afternoon = AssistantNudge.compose(
        at: DateTime(2026, 9, 27, 14),
        hasCartItems: false,
      );
      expect(afternoon.message, AssistantNudgeMessage.general);
      expect(afternoon.starters.first, AssistantStarter.offers);
    });

    test('the first meeting invites to the tour and keeps it a seat', () {
      final nudge = AssistantNudge.compose(
        at: morning,
        hasCartItems: true,
        firstMeeting: true,
      );
      expect(nudge.message, AssistantNudgeMessage.invite);
      expect(nudge.invitesTour, isTrue);
      expect(nudge.starters, hasLength(AssistantNudge.starterCount - 1));
      expect(nudge.starters.first, AssistantStarter.completeCart);
      expect(
        AssistantNudge.compose(at: morning, hasCartItems: true).invitesTour,
        isFalse,
      );
    });
  });

  group('onboarding', () {
    test('the tour is remembered once, the first date kept', () {
      expect(AssistantNudgeLog.empty.isOnboarded, isFalse);
      final met = AssistantNudgeLog.empty.onboarded(morning);
      expect(met.isOnboarded, isTrue);
      expect(met.onboarded(evening).onboardedAt, morning);
      // Greeting bookkeeping never forgets the meeting.
      final later = met
          .shownAt(evening)
          .record(AssistantNudgeOutcome.dismissed, evening)
          .hideLauncherUntil(nextMorning);
      expect(later.onboardedAt, morning);
    });

    test('the steps run hello → ready and only the last is last', () {
      expect(
        AssistantOnboardingStep.values.first,
        AssistantOnboardingStep.hello,
      );
      expect(AssistantOnboardingStep.values.last.isLast, isTrue);
      expect(
        AssistantOnboardingStep.values.where((step) => step.isLast),
        hasLength(1),
      );
      final keys = {
        for (final step in AssistantOnboardingStep.values) ...[
          step.titleKey,
          step.bodyKey,
          step.sceneKey,
        ],
      };
      expect(keys, hasLength(AssistantOnboardingStep.values.length * 3));
    });

    test('only the hello step greets by name', () {
      expect(
        AssistantOnboardingStep.hello.titleKeyFor(withName: true),
        'assistant.onboarding_hello_title_name',
      );
      expect(
        AssistantOnboardingStep.hello.titleKeyFor(withName: false),
        AssistantOnboardingStep.hello.titleKey,
      );
      expect(
        AssistantOnboardingStep.cart.titleKeyFor(withName: true),
        AssistantOnboardingStep.cart.titleKey,
      );
    });
  });

  group('use cases', () {
    late InMemoryAssistantNudgeRepository repository;

    setUp(() => repository = InMemoryAssistantNudgeRepository.met());

    test(
      'claiming records the showing and answers the greeting once',
      () async {
        final claim = ClaimAssistantNudgeUseCase(repository);
        final first = await claim(
          ClaimAssistantNudgeParams(at: morning, hasCartItems: false),
        );
        expect(
          first.getOrElse(() => null)?.message,
          AssistantNudgeMessage.morning,
        );
        expect(repository.log.lastShownAt, morning);

        final again = await claim(
          ClaimAssistantNudgeParams(at: evening, hasCartItems: false),
        );
        expect(again, const Right<Failure, AssistantNudge?>(null));
      },
    );

    test("a newcomer's first greeting invites to the tour", () async {
      final newcomer = InMemoryAssistantNudgeRepository();
      final nudge = (await ClaimAssistantNudgeUseCase(newcomer)(
        ClaimAssistantNudgeParams(at: morning, hasCartItems: false),
      )).getOrElse(() => null);
      expect(nudge?.invitesTour, isTrue);
      // Claiming alone does not count as meeting the assistant.
      expect(newcomer.log.isOnboarded, isFalse);
    });

    test('completing the tour is read back as met', () async {
      final newcomer = InMemoryAssistantNudgeRepository();
      final getOnboarded = GetAssistantOnboardedUseCase(newcomer);
      expect(
        await getOnboarded(const NoParams()),
        const Right<Failure, bool>(false),
      );
      await CompleteAssistantOnboardingUseCase(newcomer)(
        CompleteAssistantOnboardingParams(at: morning),
      );
      expect(
        await getOnboarded(const NoParams()),
        const Right<Failure, bool>(true),
      );
      expect(newcomer.log.onboardedAt, morning);
    });

    test('an unreadable log fails the onboarding write', () async {
      repository.readFailure = const CacheFailure('broken');
      final result = await CompleteAssistantOnboardingUseCase(repository)(
        CompleteAssistantOnboardingParams(at: morning),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.writes, 0);
    });

    test('an unreadable log fails the claim without writing', () async {
      repository.readFailure = const CacheFailure('broken');
      final result = await ClaimAssistantNudgeUseCase(repository)(
        ClaimAssistantNudgeParams(at: morning, hasCartItems: false),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.writes, 0);
    });

    test('an outcome is written to the log', () async {
      await RecordAssistantNudgeOutcomeUseCase(repository)(
        RecordAssistantNudgeOutcomeParams(
          outcome: AssistantNudgeOutcome.dismissed,
          at: morning,
        ),
      );
      expect(repository.log.snoozedUntil, isNotNull);
    });

    test('hiding the launcher is read back until midnight', () async {
      await HideAssistantLauncherUseCase(repository)(
        HideAssistantLauncherParams(at: morning),
      );
      final getHidden = GetAssistantLauncherHiddenUseCase(repository);
      expect(
        await getHidden(GetAssistantLauncherHiddenParams(at: evening)),
        const Right<Failure, bool>(true),
      );
      expect(
        await getHidden(GetAssistantLauncherHiddenParams(at: nextMorning)),
        const Right<Failure, bool>(false),
      );
    });
  });
}
