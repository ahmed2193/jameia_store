import 'package:flutter/widgets.dart';

import 'assistant_typing_scope.dart';
import 'assistant_typing_signal.dart';

/// Owns the chat's [AssistantTypingSignal] for the life of the chat page and
/// provides it ([AssistantTypingScope]) to the header and the composer.
class AssistantTypingHost extends StatefulWidget {
  const AssistantTypingHost({super.key, required this.child});

  final Widget child;

  @override
  State<AssistantTypingHost> createState() => _AssistantTypingHostState();
}

class _AssistantTypingHostState extends State<AssistantTypingHost> {
  final AssistantTypingSignal _signal = AssistantTypingSignal();

  @override
  void dispose() {
    _signal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AssistantTypingScope(signal: _signal, child: widget.child);
}
