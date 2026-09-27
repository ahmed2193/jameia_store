import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge_log.dart';
import 'package:jameia_mart/src/features/assistant/domain/repositories/assistant_nudge_repository.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/claim_assistant_nudge_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/complete_assistant_onboarding_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/get_assistant_launcher_hidden_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/get_assistant_onboarded_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/hide_assistant_launcher_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/record_assistant_nudge_outcome_usecase.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_buddy_cubit.dart';

/// The greeting log in memory; [readFailure] makes every read fail.
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

  @override
  Future<Either<Failure, Unit>> saveLog(AssistantNudgeLog log) async {
    writes++;
    this.log = log;
    return const Right(unit);
  }
}

/// A buddy cubit over the real use cases and [repository], with a settable
/// clock and short waits.
AssistantBuddyCubit buddyCubit(
  InMemoryAssistantNudgeRepository repository, {
  required DateTime Function() clock,
  Duration dwell = const Duration(milliseconds: 40),
  Duration quiet = const Duration(milliseconds: 20),
  Duration coachFor = const Duration(milliseconds: 60),
}) => AssistantBuddyCubit(
  claim: ClaimAssistantNudgeUseCase(repository),
  record: RecordAssistantNudgeOutcomeUseCase(repository),
  getHidden: GetAssistantLauncherHiddenUseCase(repository),
  hide: HideAssistantLauncherUseCase(repository),
  getOnboarded: GetAssistantOnboardedUseCase(repository),
  completeOnboarding: CompleteAssistantOnboardingUseCase(repository),
  dwell: dwell,
  quiet: quiet,
  coachFor: coachFor,
  clock: clock,
);
