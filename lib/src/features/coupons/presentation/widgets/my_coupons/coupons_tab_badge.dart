import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Orange count bubble on a coupon tab; pops in, and again whenever [count]
/// changes.
class CouponsTabBadge extends StatelessWidget {
  const CouponsTabBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return PopScale(
      popKey: count,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: AppSize.s18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: kHeroPillPin,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s5,
              vertical: AppSpacing.s1,
            ),
            child: Text(
              '$count',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.white,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
