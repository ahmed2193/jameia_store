import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';

/// The dark selection pill under the coupon tabs. It rides the tab
/// controller's [animation] (a tap glides it, a swipe drags it along), one
/// slot of [pillWidth] + [gap] per tab; a paint-only translation that
/// mirrors under RTL. A direct child of the tabs' `Stack`.
class CouponsTabThumb extends StatelessWidget {
  const CouponsTabThumb({
    super.key,
    required this.animation,
    required this.pillWidth,
    required this.gap,
  });

  final Animation<double> animation;
  final double pillWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final towardsEnd = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    return PositionedDirectional(
      start: 0,
      top: 0,
      bottom: 0,
      width: pillWidth,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(animation.value * (pillWidth + gap) * towardsEnd, 0),
          child: child,
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryText,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            boxShadow: AppShadows.medium,
          ),
        ),
      ),
    );
  }
}
