import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/count_badge.dart';

/// Orange count bubble on a coupon tab ([CountBadge]): there as is when the
/// page opens; it bumps and rolls when [count] changes, and fades away at
/// zero. [margin] is the gap to the tab label, kept only while it shows.
class CouponsTabBadge extends StatelessWidget {
  const CouponsTabBadge({
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
      color: kHeroPillPin,
      textStyle: AppTextStyles.captionMedium.copyWith(
        fontWeight: AppTextStyles.bold,
      ),
      minSize: AppSize.s18,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s1,
      ),
      margin: margin,
    );
  }
}
