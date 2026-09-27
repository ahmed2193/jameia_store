import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/assistant_nudge_repository.dart';

class GetAssistantLauncherHiddenParams extends Equatable {
  const GetAssistantLauncherHiddenParams({required this.at});

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Whether the customer hid the floating launcher and it is still hidden at
/// [GetAssistantLauncherHiddenParams.at].
class GetAssistantLauncherHiddenUseCase
    implements UseCase<bool, GetAssistantLauncherHiddenParams> {
  const GetAssistantLauncherHiddenUseCase(this._repository);

  final AssistantNudgeRepository _repository;

  @override
  Future<Either<Failure, bool>> call(
    GetAssistantLauncherHiddenParams params,
  ) async => (await _repository.getLog()).map(
    (log) => log.isLauncherHiddenAt(params.at),
  );
}
