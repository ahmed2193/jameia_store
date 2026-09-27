import 'package:equatable/equatable.dart';

import 'assistant_voice_problem.dart';

/// What a voice message reports while the customer speaks: words and
/// loudness as they come, then exactly one [AssistantVoiceDone] or
/// [AssistantVoiceFailed], and nothing after it. A cancelled message ends
/// with neither.
sealed class AssistantVoiceEvent extends Equatable {
  const AssistantVoiceEvent();
}

/// Every word heard so far — the whole message, not the latest phrase.
final class AssistantVoiceHeard extends AssistantVoiceEvent {
  const AssistantVoiceHeard(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// How loud the customer is right now: 0 (silence) to 1.
final class AssistantVoiceLevel extends AssistantVoiceEvent {
  const AssistantVoiceLevel(this.level);

  final double level;

  @override
  List<Object?> get props => [level];
}

/// Listening stopped as asked; [text] is everything heard (may be empty).
final class AssistantVoiceDone extends AssistantVoiceEvent {
  const AssistantVoiceDone(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The recognizer gave up. [text] is what it heard before — kept, so the
/// customer never loses words they already said.
final class AssistantVoiceFailed extends AssistantVoiceEvent {
  const AssistantVoiceFailed(this.problem, {this.text = ''});

  final AssistantVoiceProblem problem;
  final String text;

  @override
  List<Object?> get props => [problem, text];
}
