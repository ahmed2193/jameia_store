import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_voice_language.dart';
import '../repositories/assistant_voice_repository.dart';

/// The language the customer last chose to talk in; `null` until they
/// choose one — the app's language is used meanwhile.
class GetAssistantVoiceLanguageUseCase
    implements UseCase<AssistantVoiceLanguage?, NoParams> {
  const GetAssistantVoiceLanguageUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Future<Either<Failure, AssistantVoiceLanguage?>> call(NoParams params) =>
      _repository.savedLanguage();
}
