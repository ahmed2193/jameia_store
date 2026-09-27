import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/pop_switcher.dart';
import '../../../domain/entities/assistant_prompt.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import '../voice/assistant_voice_drag.dart';
import '../voice/assistant_voice_mic_button.dart';
import 'assistant_send_button.dart';

/// The button beside the message box, as in WhatsApp: the mic while the
/// box is empty, send once something is typed, stop while a reply streams.
/// The mic stays for a whole recording — the finger that holds it must
/// keep talking to the same button.
class AssistantComposerAction extends StatelessWidget {
  const AssistantComposerAction({
    super.key,
    required this.text,
    required this.drag,
    required this.holdHint,
    required this.onSend,
  });

  /// What is typed in the message box.
  final String text;
  final ValueNotifier<AssistantVoiceDrag> drag;

  /// The "hold to record" tooltip, shown after a mere tap on the mic. It
  /// wraps the switcher, not the mic: a mic on its way out and one on its
  /// way back must not share the key.
  final GlobalKey<TooltipState> holdHint;
  final VoidCallback onSend;

  static const String _micKey = 'mic';
  static const String _sendKey = 'send';

  @override
  Widget build(BuildContext context) {
    final (streaming, canSend) = context
        .select<AssistantChatCubit, (bool, bool)>(
          (cubit) => (cubit.state.isStreaming, cubit.state.canSend),
        );
    final (phase, voiceAvailable) = context
        .select<AssistantVoiceCubit, (AssistantVoicePhase, bool)>(
          (cubit) => (cubit.state.phase, cubit.state.available),
        );
    final typed = AssistantPrompt.statusOf(text) != AssistantPromptStatus.empty;
    final mic =
        phase != AssistantVoicePhase.idle ||
        (!streaming && !typed && voiceAvailable);
    return Tooltip(
      key: holdHint,
      message: 'assistant.voice.hold_to_record'.tr(),
      triggerMode: TooltipTriggerMode.manual,
      excludeFromSemantics: true,
      preferBelow: false,
      child: PopSwitcher(
        stateKey: mic ? _micKey : _sendKey,
        child: mic
            ? AssistantVoiceMicButton(drag: drag)
            : AssistantSendButton(
                streaming: streaming,
                enabled: canSend && typed,
                onSend: onSend,
                onStop: () => context.read<AssistantChatCubit>().stop(),
              ),
      ),
    );
  }
}
