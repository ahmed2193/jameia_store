import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/assistant_voice_repository.dart';

/// Stops listening and keeps the words: they arrive as the voice message's
/// done event.
class FinishAssistantVoiceUseCase implements UseCase<Unit, NoParams> {
  const FinishAssistantVoiceUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.finish();
}
