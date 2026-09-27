import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/assistant_nudge_repository.dart';

/// Whether the customer has already met the assistant (seen its tour).
class GetAssistantOnboardedUseCase implements UseCase<bool, NoParams> {
  const GetAssistantOnboardedUseCase(this._repository);

  final AssistantNudgeRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async =>
      (await _repository.getLog()).map((log) => log.isOnboarded);
}
