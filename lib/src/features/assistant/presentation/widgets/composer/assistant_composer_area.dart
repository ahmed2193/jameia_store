import 'package:flutter/material.dart';

import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/shake_x.dart';
import '../../cubit/assistant_voice_state.dart';
import '../voice/assistant_voice_discard.dart';
import '../voice/assistant_voice_drag.dart';
import '../voice/assistant_voice_hold_bar.dart';
import '../voice/assistant_voice_locked_controls.dart';
import 'assistant_composer_field.dart';

/// The message box's place in the row: the text field — or, while the mic
/// records, the hold bar / the hands-free controls on top of it (docs/motion
/// §9.6 §2.9: field, hold bar and locked controls cross-fade over `fast`).
/// The field stays mounted underneath (same size, no input while covered),
/// so the keyboard, the focus and anything typed survive a recording and
/// the row never jumps. After a cancel the bin plays over the field's start
/// without covering it: the field is back — and takes input — at once.
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
    final covered = phase.isRecording;
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        IgnorePointer(
          ignoring: covered,
          child: ExcludeSemantics(
            excluding: covered,
            child: AnimatedOpacity(
              opacity: covered ? 0 : 1,
              duration: MotionGuard.duration(context, AppMotion.fast),
              child: ShakeX(
                shakeKey: shakes,
                child: AssistantComposerField(
                  controller: controller,
                  focusNode: focusNode,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          // A bar still fading out never takes a tap meant for the field.
          child: IgnorePointer(
            ignoring: !covered,
            child: FadeThroughSwitcher(
              stateKey: covered ? phase : AssistantVoicePhase.idle,
              crossFade: true,
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox.expand(
                child: switch (phase) {
                  AssistantVoicePhase.holding => AssistantVoiceHoldBar(
                    drag: drag,
                  ),
                  AssistantVoicePhase.locked =>
                    const AssistantVoiceLockedControls(),
                  _ => null,
                },
              ),
            ),
          ),
        ),
        if (binning)
          Positioned.fill(
            child: IgnorePointer(
              child: AssistantVoiceDiscard(
                key: ValueKey<int>(bins),
                onDone: onBinned,
              ),
            ),
          ),
      ],
    );
  }
}
