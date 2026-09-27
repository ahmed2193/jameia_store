import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_voice_language.dart';
import '../repositories/assistant_voice_repository.dart';

class SaveAssistantVoiceLanguageParams extends Equatable {
  const SaveAssistantVoiceLanguageParams(this.language);

  final AssistantVoiceLanguage language;

  @override
  List<Object?> get props => [language];
}

/// Remembers the language the customer switched to, so their next voice
/// messages start in it.
class SaveAssistantVoiceLanguageUseCase
    implements UseCase<Unit, SaveAssistantVoiceLanguageParams> {
  const SaveAssistantVoiceLanguageUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveAssistantVoiceLanguageParams params) =>
      _repository.saveLanguage(params.language);
}
