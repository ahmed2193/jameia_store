import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import 'assistant_voice_blink_dot.dart';
import 'assistant_voice_drag.dart';
import 'assistant_voice_slide_hint.dart';
import 'assistant_voice_timer.dart';

/// The message box while the mic is held: the blinking mic and the timer
/// at the start, "‹ Slide to cancel" toward the mic. Same shape as the
/// text field it covers, so the field seems to turn into it. A screen
/// reader exploring it hears what the gesture does, in one phrase.
class AssistantVoiceHoldBar extends StatelessWidget {
  const AssistantVoiceHoldBar({super.key, required this.drag});

  final ValueListenable<AssistantVoiceDrag> drag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'assistant.voice.a11y_recording'.tr(),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.smallBackground,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          child: Row(
            children: [
              const AssistantVoiceBlinkDot(),
              const SizedBox(width: AppSpacing.s6),
              const AssistantVoiceTimer(),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AssistantVoiceSlideHint(drag: drag),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
