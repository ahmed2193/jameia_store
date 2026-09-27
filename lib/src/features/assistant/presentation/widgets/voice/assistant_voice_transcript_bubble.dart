import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/assistant_voice_language.dart';
import '../../cubit/assistant_voice_state.dart';
import 'assistant_voice_language_switch.dart';
import 'assistant_voice_lock_pill.dart';
import 'assistant_voice_transcript_card.dart';

/// The words heard so far, on the end side like the customer's own bubble,
/// and beside them while recording the language they are heard in, a tap
/// to switch. It clears the lock while the mic is held.
class AssistantVoiceTranscriptBubble extends StatelessWidget {
  const AssistantVoiceTranscriptBubble({
    super.key,
    required this.transcript,
    required this.phase,
    this.language,
  });

  final String transcript;
  final AssistantVoicePhase phase;
  final AssistantVoiceLanguage? language;

  /// The lock's width and its gap: the bubble stays clear of it.
  static const double _clearOfLock =
      AssistantVoiceLockPill.width + AppSpacing.s20;

  @override
  Widget build(BuildContext context) {
    final spoken = language;
    return AnimatedPadding(
      duration: MotionGuard.duration(context, AppMotion.fast),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s8,
        phase == AssistantVoicePhase.holding ? _clearOfLock : AppSpacing.s12,
        AppSpacing.s8,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (spoken != null && phase.isRecording) ...[
              AssistantVoiceLanguageSwitch(language: spoken),
              const SizedBox(width: AppSpacing.s8),
            ],
            Flexible(
              child: AssistantVoiceTranscriptCard(
                transcript: transcript,
                finishing: phase.isFinishing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
