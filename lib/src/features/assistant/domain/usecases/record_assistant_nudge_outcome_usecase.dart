import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_nudge_outcome.dart';
import '../entities/assistant_nudge_policy.dart';
import '../repositories/assistant_nudge_repository.dart';

class RecordAssistantNudgeOutcomeParams extends Equatable {
  const RecordAssistantNudgeOutcomeParams({
    required this.outcome,
    required this.at,
  });

  final AssistantNudgeOutcome outcome;
  final DateTime at;

  @override
  List<Object?> get props => [outcome, at];
}

/// Remembers how a greeting ended (or that the launcher opened the chat),
/// which decides when the next greeting may come.
class RecordAssistantNudgeOutcomeUseCase
    implements UseCase<Unit, RecordAssistantNudgeOutcomeParams> {
  const RecordAssistantNudgeOutcomeUseCase(
    this._repository, {
    this.policy = const AssistantNudgePolicy(),
  });

  final AssistantNudgeRepository _repository;
  final AssistantNudgePolicy policy;

  @override
  Future<Either<Failure, Unit>> call(
    RecordAssistantNudgeOutcomeParams params,
  ) async {
    final read = await _repository.getLog();
    return read.fold(
      Left.new,
      (log) => _repository.saveLog(
        log.record(params.outcome, params.at, policy: policy),
      ),
    );
  }
}
