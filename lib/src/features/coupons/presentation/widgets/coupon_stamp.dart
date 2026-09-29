import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';

/// Rubber stamp over a spent coupon ("USED" / "EXPIRED"): a tilted, double
/// ruled frame in [color] that pops in once, after its ticket has landed
/// ([AfterArrival], backlog B2-03). The tilt mirrors under RTL.
class CouponStamp extends StatelessWidget {
  const CouponStamp({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  /// About -12° (radians).
  static const double _tilt = -0.21;
  static const double _fillAlpha = 0.9;
  static const double _innerAlpha = 0.5;
  static const double _letterSpacing = AppSize.s1;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Keeps its place (and size) while the ticket rises in, then pops.
    final stamp = Transform.rotate(
      angle: rtl ? -_tilt : _tilt,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: _fillAlpha),
          borderRadius: BorderRadius.circular(AppRadius.r5),
          border: Border.all(color: color, width: AppSize.s2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r6),
              border: Border.all(color: color.withValues(alpha: _innerAlpha)),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s10,
                vertical: AppSpacing.s2,
              ),
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.headingSmall.copyWith(
                  color: color,
                  fontWeight: AppTextStyles.bold,
                  letterSpacing: _letterSpacing,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return AfterArrival(
      builder: (context, landed) => landed
          ? PopScale.onMount(child: stamp)
          : Visibility.maintain(visible: false, child: stamp),
    );
  }
}
