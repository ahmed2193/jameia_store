import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/count_badge.dart';

/// Unread-count pill next to a menu label ([CountBadge]): 20dp tall, bold
/// 12dp, "99+" above 99 (laid out left-to-right, so Arabic does not show
/// "+99"). It appears as is — never a pop on mount or on a tab visit — and
/// bumps once, rolling its number, only when the count CHANGES while on
/// screen; at zero it fades away. [margin] is the gap to the label, kept only
/// while it shows. Reduced motion → a tint instead of the bump.
class MineUnreadBadge extends StatelessWidget {
  const MineUnreadBadge({
    super.key,
    required this.count,
    this.margin = EdgeInsetsDirectional.zero,
  });

  final int count;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return CountBadge(
      count: count,
      color: AppColors.unreadBadgeBg,
      textColor: AppColors.skuOptionFg,
      textStyle: AppTextStyles.captionLarge.copyWith(
        fontWeight: AppTextStyles.bold,
        height: AppSize.s1,
      ),
      minSize: AppSize.s20,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
      margin: margin,
    );
  }
}
