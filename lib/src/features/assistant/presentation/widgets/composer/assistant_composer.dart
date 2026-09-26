import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/shake_x.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../domain/entities/assistant_message_entity.dart';
import '../../../domain/entities/assistant_prompt.dart';
import '../../../domain/entities/assistant_thread.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import 'assistant_char_counter.dart';
import 'assistant_composer_field.dart';
import 'assistant_send_button.dart';

/// The message box: a growing field, the counter near the limit, and one
/// button that sends — or stops the reply while it streams. An over-long
/// message shakes and says why; a sent one clears the field (the text stays
/// when the chat refused it).
class AssistantComposer extends StatefulWidget {
  const AssistantComposer({super.key});

  @override
  State<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends State<AssistantComposer> {
  final TextEditingController _controller = TextEditingController();
  int _shakes = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    switch (AssistantPrompt.statusOf(text)) {
      case AssistantPromptStatus.empty:
        return;
      case AssistantPromptStatus.tooLong:
        Haptics.warning();
        setState(() => _shakes++);
        showJameiaSnackBar(
          context,
          'assistant.too_long'.tr(
            namedArgs: {'max': '${AssistantPrompt.maxLength}'},
          ),
        );
      case AssistantPromptStatus.valid:
        if (context.read<AssistantChatCubit>().send(text)) {
          Haptics.tap();
          _controller.clear();
        }
    }
  }

  /// A message refused before its reply began (offline, 429, …) comes back
  /// to an empty field, ready to send again (its bubble also offers retry).
  void _restoreUnsent(BuildContext context, AssistantChatState state) {
    if (_controller.text.trim().isNotEmpty) return;
    final entries = state.thread.entries;
    final last = entries.isEmpty ? null : entries.last;
    if (last is AssistantMessageEntry &&
        last.message.delivery == AssistantDelivery.failed) {
      _controller.text = last.message.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (streaming, canSend) = context
        .select<AssistantChatCubit, (bool, bool)>(
          (cubit) => (cubit.state.isStreaming, cubit.state.canSend),
        );
    return BlocListener<AssistantChatCubit, AssistantChatState>(
      listenWhen: (_, current) =>
          current.notice == AssistantChatNotice.sendFailed,
      listener: _restoreUnsent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s12,
              AppSpacing.s8,
              AppSpacing.s8,
              AppSpacing.s8,
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (AssistantPrompt.showsCounter(value.text))
                    AssistantCharCounter(
                      length: AssistantPrompt.lengthOf(value.text.trim()),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: ShakeX(
                          shakeKey: _shakes,
                          child: AssistantComposerField(
                            controller: _controller,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      AssistantSendButton(
                        streaming: streaming,
                        enabled:
                            canSend &&
                            AssistantPrompt.statusOf(value.text) !=
                                AssistantPromptStatus.empty,
                        onSend: _submit,
                        onStop: () => context.read<AssistantChatCubit>().stop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
