import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import 'assistant_voice_blink_dot.dart';
import 'assistant_voice_timer.dart';
import 'assistant_voice_wave_view.dart';

/// The top line of a hands-free recording (WhatsApp's locked bar): the
/// blinking mic, the timer and the live waveform. The bin, stop and send
/// buttons sit on the line below.
class AssistantVoiceLockedPanel extends StatelessWidget {
  const AssistantVoiceLockedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s4,
        AppSpacing.s12,
        AppSpacing.s8,
      ),
      child: Row(
        children: [
          AssistantVoiceBlinkDot(),
          SizedBox(width: AppSpacing.s6),
          AssistantVoiceTimer(),
          SizedBox(width: AppSpacing.s12),
          Expanded(child: AssistantVoiceWaveView()),
        ],
      ),
    );
  }
}
