import '../../domain/entities/assistant_voice_access.dart';
import '../../domain/entities/assistant_voice_event.dart';
import '../../domain/entities/assistant_voice_problem.dart';
import '../models/assistant_speech_signal_model.dart';
import '../models/assistant_voice_update_model.dart';

extension AssistantVoiceAccessMapper on AssistantVoiceAccessModel {
  AssistantVoiceAccess toEntity() => switch (this) {
    AssistantVoiceAccessModel.granted => AssistantVoiceAccess.granted,
    AssistantVoiceAccessModel.denied => AssistantVoiceAccess.denied,
    AssistantVoiceAccessModel.blocked => AssistantVoiceAccess.blocked,
    AssistantVoiceAccessModel.unavailable => AssistantVoiceAccess.unavailable,
  };
}

extension AssistantVoiceUpdateMapper on AssistantVoiceUpdateModel {
  AssistantVoiceEvent toEntity() => switch (this) {
    AssistantVoiceHeardModel(:final text) => AssistantVoiceHeard(text),
    AssistantVoiceLevelModel(:final level) => AssistantVoiceLevel(level),
    AssistantVoiceDoneModel(:final text) => AssistantVoiceDone(text),
    AssistantVoiceFailedModel(:final kind, :final text) => AssistantVoiceFailed(
      kind.toProblem(),
      text: text,
    ),
  };
}

extension AssistantSpeechErrorKindMapper on AssistantSpeechErrorKind {
  AssistantVoiceProblem toProblem() => switch (this) {
    AssistantSpeechErrorKind.noSpeech => AssistantVoiceProblem.noSpeech,
    AssistantSpeechErrorKind.retry => AssistantVoiceProblem.busy,
    AssistantSpeechErrorKind.network => AssistantVoiceProblem.network,
    AssistantSpeechErrorKind.language => AssistantVoiceProblem.language,
    AssistantSpeechErrorKind.permission => AssistantVoiceProblem.permission,
    AssistantSpeechErrorKind.ignore ||
    AssistantSpeechErrorKind.other => AssistantVoiceProblem.other,
  };
}
