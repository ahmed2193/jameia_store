import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_prompt.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import '../voice/assistant_voice_drag.dart';
import '../voice/assistant_voice_lock_pill.dart';
import '../voice/assistant_voice_locked_panel.dart';
import '../voice/assistant_voice_reveal.dart';
import 'assistant_char_counter.dart';
import 'assistant_composer_action.dart';
import 'assistant_composer_area.dart';

/// The composer's content: the counter near the limit, the hands-free
/// recording's timer and waveform, then the row — message box and its
/// button — with the lock floating above the held mic.
class AssistantComposerBar extends StatelessWidget {
  const AssistantComposerBar({
    super.key,
    required this.text,
    required this.controller,
    required this.focusNode,
    required this.shakes,
    required this.drag,
    required this.holdHint,
    required this.bins,
    required this.binning,
    required this.onBinned,
    required this.onSend,
  });

  /// What is typed in the message box.
  final String text;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int shakes;
  final ValueNotifier<AssistantVoiceDrag> drag;
  final GlobalKey<TooltipState> holdHint;
  final int bins;
  final bool binning;
  final VoidCallback onBinned;
  final VoidCallback onSend;

  /// The lock is centred over the mic, clear of the held mic's halo.
  static const double _lockEnd =
      (AppSize.s48 - AssistantVoiceLockPill.width) / 2;
  static const double _lockBottom = AppSize.s96;

  @override
  Widget build(BuildContext context) {
    final phase = context.select<AssistantVoiceCubit, AssistantVoicePhase>(
      (cubit) => cubit.state.phase,
    );
    final locked = phase == AssistantVoicePhase.locked;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Folds in over `fast` near the limit instead of pushing the
            // box up in one frame (docs/motion §9.6 §2.12).
            CollapseReveal(
              visible: !phase.isRecording && AssistantPrompt.showsCounter(text),
              duration: AppMotion.fast,
              alignment: AlignmentDirectional.bottomEnd,
              child: AssistantCharCounter(
                length: AssistantPrompt.lengthOf(text.trim()),
              ),
            ),
            AssistantVoiceReveal(
              shown: locked,
              child: const AssistantVoiceLockedPanel(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AssistantComposerArea(
                    phase: phase,
                    controller: controller,
                    focusNode: focusNode,
                    shakes: shakes,
                    drag: drag,
                    bins: bins,
                    binning: binning,
                    onBinned: onBinned,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                AssistantComposerAction(
                  text: text,
                  drag: drag,
                  holdHint: holdHint,
                  onSend: onSend,
                ),
              ],
            ),
          ],
        ),
        if (phase == AssistantVoicePhase.holding)
          PositionedDirectional(
            end: _lockEnd,
            bottom: _lockBottom,
            child: AssistantVoiceLockPill(drag: drag),
          ),
      ],
    );
  }
}
