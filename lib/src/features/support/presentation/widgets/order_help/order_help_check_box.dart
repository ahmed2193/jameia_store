import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// The box at the end of an item row: a 20 dp rounded square that fills
/// with the brand ink when [checked], the tick springing in (easing out when
/// cleared) — the square sister of `HeroRadioMark`. Decorative: the row
/// carries the checked semantics.
class OrderHelpCheckBox extends StatelessWidget {
  const OrderHelpCheckBox({super.key, required this.checked});

  final bool checked;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.r6),
  );

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.fast);
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.signature,
        width: AppSize.s20,
        height: AppSize.s20,
        decoration: BoxDecoration(
          color: checked ? AppColors.primaryDark : AppColors.white,
          borderRadius: _radius,
          border: Border.all(
            color: checked ? AppColors.primaryDark : AppColors.secondaryText,
            width: AppSize.s2,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedScale(
          scale: checked ? 1 : 0,
          duration: checked
              ? MotionGuard.duration(context, AppSprings.snappy.duration)
              : duration,
          curve: checked ? AppSprings.snappy : AppMotion.exit,
          child: const HeroIcon(
            HeroIcons.check,
            size: AppSize.s14,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
