import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_nudge_log.dart';
import 'package:hero_mart/src/features/assistant/domain/repositories/assistant_nudge_repository.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/claim_assistant_nudge_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/complete_assistant_onboarding_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_launcher_hidden_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_onboarded_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/hide_assistant_launcher_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/record_assistant_nudge_outcome_usecase.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_buddy_cubit.dart';

/// The greeting log in memory; [readFailure] makes every read fail and
/// [writes] counts the changes stored.
///
/// [met] starts from a log of a customer who already took the tour, the
/// usual state for the launcher and greeting tests.
class InMemoryAssistantNudgeRepository implements AssistantNudgeRepository {
  InMemoryAssistantNudgeRepository([this.log = AssistantNudgeLog.empty]);

  InMemoryAssistantNudgeRepository.met()
    : log = AssistantNudgeLog.empty.onboarded(DateTime(2026));

  AssistantNudgeLog log;
  Failure? readFailure;
  int writes = 0;

  @override
  Future<Either<Failure, AssistantNudgeLog>> getLog() async {
    final failure = readFailure;
    return failure == null ? Right(log) : Left(failure);
  }

  // Like the real store: the change applies to the log as it is when the
  // call is made, before any await.
  @override
  Future<Either<Failure, AssistantNudgeLog>> updateLog(
    AssistantNudgeLog Function(AssistantNudgeLog log) change,
  ) async {
    final failure = readFailure;
    if (failure != null) return Left(failure);
    final next = change(log);
    if (next != log) {
      writes++;
      log = next;
    }
    return Right(next);
  }
}

/// A buddy cubit over the real use cases and [repository], with a settable
/// clock, short waits and seeded lines. The launcher's first thought waits
/// [thinkAfter] and the next one [thinkEvery] — a day unless a test is
/// about them.
AssistantBuddyCubit buddyCubit(
  InMemoryAssistantNudgeRepository repository, {
  required DateTime Function() clock,
  Duration dwell = const Duration(milliseconds: 40),
  Duration quiet = const Duration(milliseconds: 20),
  Duration thinkAfter = const Duration(days: 1),
  Duration thinkQuiet = const Duration(milliseconds: 20),
  Duration thinkEvery = const Duration(days: 1),
  Random? random,
}) => AssistantBuddyCubit(
  claim: ClaimAssistantNudgeUseCase(repository),
  record: RecordAssistantNudgeOutcomeUseCase(repository),
  getHidden: GetAssistantLauncherHiddenUseCase(repository),
  hide: HideAssistantLauncherUseCase(repository),
  getOnboarded: GetAssistantOnboardedUseCase(repository),
  completeOnboarding: CompleteAssistantOnboardingUseCase(repository),
  dwell: dwell,
  quiet: quiet,
  thinkAfter: thinkAfter,
  thinkQuiet: thinkQuiet,
  thinkEvery: thinkEvery,
  random: random ?? Random(1),
  clock: clock,
);
