import 'package:equatable/equatable.dart';

import '../../../domain/entities/assistant_starter.dart';

/// How the customer left the assistant's tour.
enum AssistantOnboardingExit {
  /// "Start chatting", or a question picked on the last step.
  chat,

  /// "Skip" before the last step, or the sheet swiped / backed away.
  skipped,

  /// "Maybe later" on the last step.
  later,
}

/// What the tour hands back: how it ended and — when the customer picked
/// one on the last step — the question to open the chat with.
class AssistantOnboardingResult extends Equatable {
  const AssistantOnboardingResult(this.exit, {this.starter});

  final AssistantOnboardingExit exit;
  final AssistantStarter? starter;

  @override
  List<Object?> get props => [exit, starter];
}
