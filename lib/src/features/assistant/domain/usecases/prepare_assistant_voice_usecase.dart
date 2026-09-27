import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_voice_access.dart';
import '../repositories/assistant_voice_repository.dart';

/// Gets the recognizer ready when the microphone is already allowed —
/// without asking the customer anything — so the first press starts at
/// once. `null` while the customer has not allowed it yet.
class PrepareAssistantVoiceUseCase
    implements UseCase<AssistantVoiceAccess?, NoParams> {
  const PrepareAssistantVoiceUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Future<Either<Failure, AssistantVoiceAccess?>> call(NoParams params) =>
      _repository.prepare();
}
