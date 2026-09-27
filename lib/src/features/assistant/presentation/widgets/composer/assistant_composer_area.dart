import 'package:flutter/material.dart';

import '../../../../../core/motion/shake_x.dart';
import '../../cubit/assistant_voice_state.dart';
import '../voice/assistant_voice_discard.dart';
import '../voice/assistant_voice_drag.dart';
import '../voice/assistant_voice_hold_bar.dart';
import '../voice/assistant_voice_locked_controls.dart';
import 'assistant_composer_field.dart';

/// The message box's place in the row: the text field — or, while the mic
/// records, the hold bar / the hands-free controls on top of it, and the
/// bin after a cancel. The field stays mounted underneath (same size, no
/// input), so the keyboard, the focus and anything typed survive a
/// recording and the row never jumps.
class AssistantComposerArea extends StatelessWidget {
  const AssistantComposerArea({
    super.key,
    required this.phase,
    required this.controller,
    required this.focusNode,
    required this.shakes,
    required this.drag,
    required this.bins,
    required this.binning,
    required this.onBinned,
  });

  final AssistantVoicePhase phase;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Bumped to shake the field (an over-long message).
  final int shakes;
  final ValueNotifier<AssistantVoiceDrag> drag;

  /// Bumped per cancel, so each one plays its own bin.
  final int bins;
  final bool binning;
  final VoidCallback onBinned;

  @override
  Widget build(BuildContext context) {
    final covered = phase.isRecording || binning;
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        Visibility(
          visible: !covered,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: ShakeX(
            shakeKey: shakes,
            child: AssistantComposerField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
        if (phase == AssistantVoicePhase.holding)
          Positioned.fill(child: AssistantVoiceHoldBar(drag: drag))
        else if (phase == AssistantVoicePhase.locked)
          const Positioned.fill(child: AssistantVoiceLockedControls())
        else if (binning)
          Positioned.fill(
            child: AssistantVoiceDiscard(
              key: ValueKey<int>(bins),
              onDone: onBinned,
            ),
          ),
      ],
    );
  }
}
