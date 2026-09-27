import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_voice_access.dart';
import '../repositories/assistant_voice_repository.dart';

/// The microphone for a voice message: asks the customer the first time
/// (the system dialog), then answers at once.
class RequestAssistantVoiceAccessUseCase
    implements UseCase<AssistantVoiceAccess, NoParams> {
  const RequestAssistantVoiceAccessUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Future<Either<Failure, AssistantVoiceAccess>> call(NoParams params) =>
      _repository.requestAccess();
}
