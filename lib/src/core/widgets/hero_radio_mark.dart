import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';

/// The radio at the end of a choice row: a 20 dp ring whose dot springs in
/// when [selected] and eases out when cleared (never springs down to 0).
/// Decorative — the row carries the checked semantics.
class HeroRadioMark extends StatelessWidget {
  const HeroRadioMark({super.key, required this.selected});

  final bool selected;

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
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.secondaryText,
            width: AppSize.s2,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: selected
              ? MotionGuard.duration(context, AppSprings.snappy.duration)
              : duration,
          curve: selected ? AppSprings.snappy : AppMotion.exit,
          child: const SizedBox.square(
            dimension: AppSpacing.s10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
