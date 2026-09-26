import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// One end of the cart stepper: a 44 dp ink icon button with its tooltip,
/// one selection haptic per tap, greyed out when [onTap] is null. With
/// [animateIcon], a new [icon] (minus ↔ bin) cross-fades in; a button whose
/// icon never changes passes false and carries no switcher.
class CartQtyStepButton extends StatelessWidget {
  const CartQtyStepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.animateIcon = true,
  });

  /// One style for every step button: built once, not per build.
  static final ButtonStyle _style = IconButton.styleFrom(
    fixedSize: const Size.square(AppSize.s44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: AppColors.primaryText,
    disabledForegroundColor: AppColors.disabledText,
  );

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool animateIcon;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    final glyph = Icon(icon, key: ValueKey<IconData>(icon), size: AppSize.s20);
    return IconButton(
      tooltip: tooltip,
      onPressed: tap == null
          ? null
          : () {
              Haptics.selection();
              tap();
            },
      style: _style,
      icon: animateIcon
          ? AnimatedSwitcher(
              duration: MotionGuard.duration(context, AppMotion.fast),
              child: glyph,
            )
          : glyph,
    );
  }
}
