import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../domain/entities/assistant_message_entity.dart';
import '../../../domain/entities/assistant_prompt.dart';
import '../../../domain/entities/assistant_thread.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import '../chat/assistant_typing_scope.dart';
import '../chat/assistant_typing_signal.dart';
import '../voice/assistant_voice_drag.dart';
import '../voice/assistant_voice_lifecycle.dart';
import '../voice/assistant_voice_listener.dart';
import '../voice/assistant_voice_transcript_preview.dart';
import 'assistant_composer_bar.dart';

/// The message box, WhatsApp style: a growing field and one button beside
/// it — the mic while the box is empty (hold to talk and let go to send,
/// slide away to cancel, slide up to talk hands-free), send once something
/// is typed, stop while a reply streams. What the mic hears shows live
/// above the box. An over-long message shakes and says why; a sent one
/// clears the field (the text stays when the chat refused it), and spoken
/// words that could not go wait in the field.
class AssistantComposer extends StatefulWidget {
  const AssistantComposer({super.key});

  @override
  State<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends State<AssistantComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ValueNotifier<AssistantVoiceDrag> _drag = ValueNotifier(
    AssistantVoiceDrag.none,
  );
  final GlobalKey<TooltipState> _holdHint = GlobalKey<TooltipState>();
  int _shakes = 0;
  int _bins = 0;
  bool _binning = false;

  /// Where the chat hears that the customer types (none outside a chat).
  AssistantTypingSignal? _typing;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_reportTyping);
    _controller.addListener(_reportTyping);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _typing = AssistantTypingScope.maybeOf(context);
  }

  /// Typing = the box has focus or holds a draft.
  void _reportTyping() =>
      _typing?.report(_focus.hasFocus || _controller.text.trim().isNotEmpty);

  @override
  void dispose() {
    // The box is gone (the chat ended, the page left): after this frame,
    // nobody is typing.
    final typing = _typing;
    if (typing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => typing.report(false));
    }
    _drag.dispose();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_send(_controller.text)) _controller.clear();
  }

  /// Sends [text], typed or spoken; `false` when it did not go.
  bool _send(String text) {
    switch (AssistantPrompt.statusOf(text)) {
      case AssistantPromptStatus.empty:
        return false;
      case AssistantPromptStatus.tooLong:
        Haptics.refuse();
        setState(() => _shakes++);
        showHeroSnackBar(
          context,
          'assistant.too_long'.tr(
            namedArgs: {'max': '${AssistantPrompt.maxLength}'},
          ),
          tone: HeroSnackTone.warning,
        );
        return false;
      case AssistantPromptStatus.valid:
        final sent = context.read<AssistantChatCubit>().send(text);
        if (sent) Haptics.commit();
        return sent;
    }
  }

  void _sendSpoken(String text) {
    if (!_send(text)) _review(text);
  }

  /// Heard words wait in the message box — after anything typed meanwhile
  /// — to be read over and sent.
  void _review(String text) {
    final words = text.trim();
    if (words.isEmpty) return;
    final typed = _controller.text.trim();
    final draft = typed.isEmpty ? words : '$typed $words';
    _controller.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
    // Not under another page: its keyboard would open over that page.
    if (ModalRoute.isCurrentOf(context) ?? true) _focus.requestFocus();
  }

  void _onDiscarded() {
    if (MotionGuard.reduced(context)) return;
    setState(() {
      _binning = true;
      _bins++;
    });
  }

  void _onBinned() {
    if (mounted) setState(() => _binning = false);
  }

  /// A new recording: a bin still playing gives way.
  void _onRecording() {
    if (_binning) setState(() => _binning = false);
  }

  void _showHoldHint() => _holdHint.currentState?.ensureTooltipVisible();

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
    return AssistantVoiceLifecycle(
      child: AssistantVoiceListener(
        onSend: _sendSpoken,
        onReview: _review,
        onDiscarded: _onDiscarded,
        onTooShort: _showHoldHint,
        onRecording: _onRecording,
        child: BlocListener<AssistantChatCubit, AssistantChatState>(
          listenWhen: (_, current) =>
              current.notice == AssistantChatNotice.sendFailed,
          listener: _restoreUnsent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AssistantVoiceTranscriptPreview(),
              DecoratedBox(
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
                      builder: (context, value, _) => AssistantComposerBar(
                        text: value.text,
                        controller: _controller,
                        focusNode: _focus,
                        shakes: _shakes,
                        drag: _drag,
                        holdHint: _holdHint,
                        bins: _bins,
                        binning: _binning,
                        onBinned: _onBinned,
                        onSend: _submit,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
