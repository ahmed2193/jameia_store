import 'package:equatable/equatable.dart';

import 'assistant_speech_signal_model.dart';

/// Whether the customer can talk, as the data layer found it.
enum AssistantVoiceAccessModel { granted, denied, blocked, unavailable }

/// What one voice message reports, stitched across the recognizer's
/// sessions: words and levels, then one done or failed update.
sealed class AssistantVoiceUpdateModel extends Equatable {
  const AssistantVoiceUpdateModel();
}

/// Every word heard so far in the message.
final class AssistantVoiceHeardModel extends AssistantVoiceUpdateModel {
  const AssistantVoiceHeardModel(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Loudness, 0..1.
final class AssistantVoiceLevelModel extends AssistantVoiceUpdateModel {
  const AssistantVoiceLevelModel(this.level);

  final double level;

  @override
  List<Object?> get props => [level];
}

/// Listening stopped as asked; [text] is the whole message.
final class AssistantVoiceDoneModel extends AssistantVoiceUpdateModel {
  const AssistantVoiceDoneModel(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The recognizer gave up with an error of [kind]; [text] was heard before.
final class AssistantVoiceFailedModel extends AssistantVoiceUpdateModel {
  const AssistantVoiceFailedModel(this.kind, {this.text = ''});

  final AssistantSpeechErrorKind kind;
  final String text;

  @override
  List<Object?> get props => [kind, text];
}
