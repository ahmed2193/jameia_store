import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/assistant_nudge_repository.dart';

class CompleteAssistantOnboardingParams extends Equatable {
  const CompleteAssistantOnboardingParams({required this.at});

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Remembers that the customer met the assistant (its tour was shown), so
/// the launcher opens the chat from now on and no greeting offers the tour
/// again. Recorded when the tour opens: leaving it half-way still counts.
class CompleteAssistantOnboardingUseCase
    implements UseCase<Unit, CompleteAssistantOnboardingParams> {
  const CompleteAssistantOnboardingUseCase(this._repository);

  final AssistantNudgeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(
    CompleteAssistantOnboardingParams params,
  ) async {
    final updated = await _repository.updateLog(
      (log) => log.onboarded(params.at),
    );
    return updated.map((_) => unit);
  }
}
