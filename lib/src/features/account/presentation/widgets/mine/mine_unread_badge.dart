import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Unread-count pill next to a menu label (bundle `i13302`): 20dp tall,
/// min-width 20dp, radius 10dp, 2dp white border, bold 12dp. Counts above 99
/// render as "99+".
class MineUnreadBadge extends StatelessWidget {
  const MineUnreadBadge({super.key, required this.count});

  static const int _maxShown = 99;

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > _maxShown ? '$_maxShown+' : '$count';
    // Grow-from-zero pop — re-pops whenever the count changes ([PopScale]).
    return PopScale(
      popKey: count,
      child: Container(
        height: AppSize.s20,
        constraints: const BoxConstraints(minWidth: AppSize.s20),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.unreadBadgeBg,
          borderRadius: BorderRadius.circular(AppSize.r10),
          border: Border.all(color: AppColors.white, width: AppSize.s2),
        ),
        child: Text(
          text,
          style: AppTextStyles.captionLarge.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.skuOptionFg,
            height: AppSize.s1,
          ),
        ),
      ),
    );
  }
}
