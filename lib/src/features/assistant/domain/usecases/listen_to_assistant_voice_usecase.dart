import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_voice_event.dart';
import '../repositories/assistant_voice_repository.dart';

class ListenToAssistantVoiceParams extends Equatable {
  const ListenToAssistantVoiceParams({required this.languageCode});

  /// The app's language: the customer is heard in it.
  final String languageCode;

  @override
  List<Object?> get props => [languageCode];
}

/// One voice message: the words as they are heard, then done or failed.
/// Cancelling the subscription drops the message and closes the
/// microphone; `FinishAssistantVoiceUseCase` ends it keeping the words.
class ListenToAssistantVoiceUseCase
    implements
        StreamUseCase<AssistantVoiceEvent, ListenToAssistantVoiceParams> {
  const ListenToAssistantVoiceUseCase(this._repository);

  final AssistantVoiceRepository _repository;

  @override
  Stream<AssistantVoiceEvent> call(ListenToAssistantVoiceParams params) =>
      _repository.listen(languageCode: params.languageCode);
}
