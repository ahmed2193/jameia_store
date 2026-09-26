import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// Send, or Stop while a reply streams — one round 48 dp button, one
/// accessibility node, the icon cross-fading between the two.
class AssistantSendButton extends StatelessWidget {
  const AssistantSendButton({
    super.key,
    required this.streaming,
    required this.enabled,
    required this.onSend,
    required this.onStop,
  });

  final bool streaming;

  /// Send is possible (text typed, the chat can take it). Stop is always
  /// enabled while streaming.
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final active = streaming || enabled;
    final VoidCallback? action = active ? (streaming ? onStop : onSend) : null;
    return Semantics(
      button: true,
      enabled: active,
      label: (streaming ? 'assistant.stop' : 'assistant.send').tr(),
      excludeSemantics: true,
      onTap: action,
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.fast),
        width: AppSize.s48,
        height: AppSize.s48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : AppColors.mediumBackground,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: action,
            child: AnimatedSwitcher(
              duration: MotionGuard.duration(context, AppMotion.fast),
              child: Icon(
                streaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                key: ValueKey(streaming),
                size: AppSize.s22,
                color: active
                    ? AppColors.brandForeground
                    : AppColors.disabledText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
