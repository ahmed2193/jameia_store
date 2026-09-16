import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../motion/haptics.dart';
import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Add / quantity stepper. When [qty] is 0 it collapses to a single round "+"
/// add button (KeeTa product-card behavior); above 0 it shows − qty +.
///
/// Motion: the collapse/expand between the lone "+" and the −qty+ row cross-fades
/// + size-animates ([AppMotion.fast]); the count itself flips ([FlipValue]); each
/// round button has the press-scale feel ([PressScale]). All reduced-motion-gated.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.size = 28,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      alignment: AlignmentDirectional.centerEnd,
      child: AnimatedSwitcher(
        duration: MotionGuard.duration(context, AppMotion.fast),
        switchInCurve: AppMotion.signature,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: qty <= 0
            ? _RoundBtn(
                key: const ValueKey<String>('add'),
                icon: Icons.add_rounded,
                bg: AppColors.primary,
                fg: AppColors.brandForeground,
                size: size,
                label: 'home.add_to_cart'.tr(),
                onTap: onAdd,
              )
            : Row(
                key: const ValueKey<String>('stepper'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundBtn(
                    icon: Icons.remove_rounded,
                    bg: AppColors.smallBackground,
                    fg: AppColors.primaryText,
                    size: size,
                    label: 'home.decrease_quantity'.tr(),
                    onTap: onRemove,
                  ),
                  Container(
                    constraints: BoxConstraints(minWidth: size),
                    alignment: Alignment.center,
                    child: FlipValue(
                      flipKey: qty,
                      alignment: Alignment.center,
                      child: Text(
                        '$qty',
                        key: ValueKey<int>(qty),
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                  ),
                  _RoundBtn(
                    icon: Icons.add_rounded,
                    bg: AppColors.primary,
                    fg: AppColors.brandForeground,
                    size: size,
                    label: 'home.increase_quantity'.tr(),
                    onTap: onAdd,
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.size,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.62, color: fg),
          ),
        ),
      ),
    );
  }
}
