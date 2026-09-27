import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_nudge.dart';
import '../entities/assistant_nudge_policy.dart';
import '../repositories/assistant_nudge_repository.dart';

class ClaimAssistantNudgeParams extends Equatable {
  const ClaimAssistantNudgeParams({
    required this.at,
    required this.hasCartItems,
  });

  final DateTime at;
  final bool hasCartItems;

  @override
  List<Object?> get props => [at, hasCartItems];
}

/// Asks for the assistant's greeting at [ClaimAssistantNudgeParams.at]:
/// `null` when the policy keeps it quiet, otherwise the greeting — and the
/// showing is recorded right away, so it counts even if the app closes.
/// A customer who never met the assistant is invited to its tour.
class ClaimAssistantNudgeUseCase
    implements UseCase<AssistantNudge?, ClaimAssistantNudgeParams> {
  const ClaimAssistantNudgeUseCase(
    this._repository, {
    this.policy = const AssistantNudgePolicy(),
  });

  final AssistantNudgeRepository _repository;
  final AssistantNudgePolicy policy;

  @override
  Future<Either<Failure, AssistantNudge?>> call(
    ClaimAssistantNudgeParams params,
  ) async {
    AssistantNudge? nudge;
    final updated = await _repository.updateLog((log) {
      if (!policy.allows(log, params.at)) return log;
      nudge = AssistantNudge.compose(
        at: params.at,
        hasCartItems: params.hasCartItems,
        firstMeeting: !log.isOnboarded,
      );
      return log.shownAt(params.at);
    });
    return updated.map((_) => nudge);
  }
}
