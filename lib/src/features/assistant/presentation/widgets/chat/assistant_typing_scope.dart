import 'package:flutter/widgets.dart';

import 'assistant_typing_signal.dart';

/// Puts the chat's [AssistantTypingSignal] where both the composer (which
/// reports) and the header's motion gate (which reads) can reach it.
class AssistantTypingScope extends InheritedNotifier<AssistantTypingSignal> {
  const AssistantTypingScope({
    super.key,
    required AssistantTypingSignal signal,
    required super.child,
  }) : super(notifier: signal);

  /// The signal, without listening (the composer reports into it).
  static AssistantTypingSignal? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AssistantTypingScope>()?.notifier;

  /// Whether the customer is typing; rebuilds [context] when it changes.
  /// `false` outside a chat.
  static bool typingOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AssistantTypingScope>()
          ?.notifier
          ?.value ??
      false;
}
