import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/assistant_voice_repository.dart';

/// Stops listening and drops the words (slid to cancel, the bin, leaving
/// the chat).
class CancelAssistantVoiceUseCase implements UseCase<Unit, NoParams> {
  const CancelAssistantVoiceUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.cancel();
}
