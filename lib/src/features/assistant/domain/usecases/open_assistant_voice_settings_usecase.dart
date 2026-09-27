import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/assistant_voice_repository.dart';

/// Opens this app's page in the system settings, where a blocked
/// microphone can be allowed again.
class OpenAssistantVoiceSettingsUseCase implements UseCase<Unit, NoParams> {
  const OpenAssistantVoiceSettingsUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.openSettings();
}
