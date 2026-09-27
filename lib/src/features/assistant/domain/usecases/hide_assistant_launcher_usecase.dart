import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_nudge_policy.dart';
import '../repositories/assistant_nudge_repository.dart';

class HideAssistantLauncherParams extends Equatable {
  const HideAssistantLauncherParams({required this.at});

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// "Hide for today": the floating launcher stays away until the next local
/// midnight (the chat is still in the home header and in Mine).
class HideAssistantLauncherUseCase
    implements UseCase<Unit, HideAssistantLauncherParams> {
  const HideAssistantLauncherUseCase(this._repository);

  final AssistantNudgeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(HideAssistantLauncherParams params) async {
    final read = await _repository.getLog();
    return read.fold(
      Left.new,
      (log) => _repository.saveLog(
        log.hideLauncherUntil(AssistantNudgePolicy.endOfDay(params.at)),
      ),
    );
  }
}
