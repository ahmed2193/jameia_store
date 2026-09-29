import 'package:flutter/foundation.dart';

/// Whether the customer is writing a message in the chat: the message box
/// has focus or holds a draft. The composer reports it; the chat's motion
/// gate reads it (docs/motion §9.6 §3.2: the mascots hold still while the
/// customer types). A report after the chat closed is dropped.
class AssistantTypingSignal extends ValueNotifier<bool> {
  AssistantTypingSignal() : super(false);

  bool _disposed = false;

  /// Sets the flag unless the chat has already closed.
  void report(bool typing) {
    if (!_disposed) value = typing;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
