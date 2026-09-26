import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Round check of the coupon picker: an empty ring, filling orange with a
/// white tick that pops in when [selected].
class CouponSelectCheck extends StatelessWidget {
  const CouponSelectCheck({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      width: AppSize.s24,
      height: AppSize.s24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? kJameiaPillPin : AppColors.white,
        border: Border.all(
          color: selected ? kJameiaPillPin : AppColors.disabledText,
          width: AppSize.s1_5,
        ),
      ),
      child: selected
          ? const PopScale.onMount(
              child: Icon(
                Icons.check_rounded,
                size: AppSize.s16,
                color: AppColors.white,
              ),
            )
          : null,
    );
  }
}
