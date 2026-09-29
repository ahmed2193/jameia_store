import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import '../buddy/buddy_motion_gate.dart';
import 'assistant_typing_scope.dart';

/// The chat's [BuddyMotionGate] (docs/motion §9.6 §3.2, §3.3): the mascots
/// in the chat stay still while a reply streams (the answer comes first),
/// while the microphone is open and while the customer types (the message
/// box has focus or holds a draft — the composer says so through
/// [AssistantTypingScope] — or the keyboard is up).
class AssistantChatMotionGate extends StatelessWidget {
  const AssistantChatMotionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final streaming = context.select<AssistantChatCubit, bool>(
      (cubit) => cubit.state.isStreaming,
    );
    final recording = context.select<AssistantVoiceCubit, bool>(
      (cubit) => cubit.state.phase != AssistantVoicePhase.idle,
    );
    final typing =
        AssistantTypingScope.typingOf(context) ||
        MediaQuery.viewInsetsOf(context).bottom > 0;
    return BuddyMotionGate(
      mayMove: !streaming && !recording && !typing,
      child: child,
    );
  }
}
