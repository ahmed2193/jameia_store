import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_loader.dart';
import '../../cubit/assistant_voice_state.dart';

/// The mic button's round face: the mic, the send arrow once locked, the
/// loader dots while the last words come in — each one popping in over the
/// last ([PopSwitcher], `snappy`). [darkened]: the held mic under reduced
/// motion, which changes colour instead of growing.
class AssistantVoiceMicFace extends StatelessWidget {
  const AssistantVoiceMicFace({
    super.key,
    required this.phase,
    this.darkened = false,
  });

  final AssistantVoicePhase phase;
  final bool darkened;

  @override
  Widget build(BuildContext context) {
    final face = switch (phase) {
      AssistantVoicePhase.sending ||
      AssistantVoicePhase.stopping => 'finishing',
      AssistantVoicePhase.locked => 'send',
      AssistantVoicePhase.idle || AssistantVoicePhase.holding => 'mic',
    };
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: darkened ? AppColors.primaryDark : AppColors.primary,
      ),
      child: SizedBox.square(
        dimension: AppSize.s48,
        child: Center(
          child: PopSwitcher(
            stateKey: face,
            alignment: AlignmentDirectional.center,
            child: switch (phase) {
              AssistantVoicePhase.sending || AssistantVoicePhase.stopping =>
                const BrandedLoader.inline(size: AppSize.s28),
              AssistantVoicePhase.locked => const Icon(
                Icons.arrow_upward_rounded,
                size: AppSize.s22,
                color: AppColors.brandForeground,
              ),
              AssistantVoicePhase.idle ||
              AssistantVoicePhase.holding => const Icon(
                Icons.mic_rounded,
                size: AppSize.s24,
                color: AppColors.brandForeground,
              ),
            },
          ),
        ),
      ),
    );
  }
}
