import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../domain/entities/rider_quick_reply.dart';

/// One one-tap message, as an outlined pill in the brand green. The whole
/// height of the row is its hit box; with no [onPressed] (a message on its
/// way) it fades back and does not dip.
class RiderChatQuickReplyChip extends StatelessWidget {
  const RiderChatQuickReplyChip({
    super.key,
    required this.reply,
    required this.onPressed,
  });

  final RiderQuickReply reply;
  final ValueChanged<RiderQuickReply>? onPressed;

  /// How far a chip fades back while it cannot be tapped.
  static const double _disabledAlpha = 0.5;

  @override
  Widget build(BuildContext context) {
    final onPressed = this.onPressed;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: PressScale(
        enabled: enabled,
        onTap: () => onPressed?.call(reply),
        child: Center(
          child: AnimatedOpacity(
            opacity: enabled ? 1 : _disabledAlpha,
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: AppMotion.signature,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.primary),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                child: Text(
                  reply.labelKey.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
