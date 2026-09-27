import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_loader.dart';
import '../../cubit/assistant_voice_state.dart';

/// The mic button's round face: the mic, the send arrow once locked, a
/// the loader dots while the last words come in.
class AssistantVoiceMicFace extends StatelessWidget {
  const AssistantVoiceMicFace({super.key, required this.phase});

  final AssistantVoicePhase phase;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: SizedBox.square(
        dimension: AppSize.s48,
        child: Center(
          child: AnimatedSwitcher(
            duration: MotionGuard.duration(context, AppMotion.fast),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: switch (phase) {
              AssistantVoicePhase.sending ||
              AssistantVoicePhase.stopping => const BrandedLoader.inline(
                key: ValueKey('finishing'),
                size: AppSize.s28,
              ),
              AssistantVoicePhase.locked => const Icon(
                Icons.arrow_upward_rounded,
                key: ValueKey('send'),
                size: AppSize.s22,
                color: AppColors.brandForeground,
              ),
              AssistantVoicePhase.idle ||
              AssistantVoicePhase.holding => const Icon(
                Icons.mic_rounded,
                key: ValueKey('mic'),
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
