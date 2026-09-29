import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';

/// The thought bubble itself: a soft white cloud, never wider than
/// [_maxWidth]. It holds still while it is up — no bob, no bump (docs/motion
/// §9.6 §3.1 row 9) — and dips a little while the mascot is [pressed] or
/// while it is pressed itself ([onTap]).
class AssistantBuddyThoughtCloud extends StatelessWidget {
  const AssistantBuddyThoughtCloud({
    super.key,
    required this.pressed,
    required this.alignment,
    required this.onTap,
    required this.child,
  });

  final bool pressed;
  final Alignment alignment;
  final VoidCallback onTap;
  final Widget child;

  static const double _maxWidth = AppSize.s240;
  static const BoxDecoration _cloud = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppSize.r18)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.brandLightBg)),
    boxShadow: AppShadows.medium,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? AppMotion.pressedScale : 1,
      duration: MotionGuard.duration(
        context,
        pressed ? AppMotion.microPop : AppMotion.fast,
      ),
      curve: AppMotion.signature,
      alignment: alignment,
      child: PressScale(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: DecoratedBox(
            decoration: _cloud,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s8,
                AppSpacing.s8,
                AppSpacing.s12,
                AppSpacing.s8,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
