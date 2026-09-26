import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import 'coupons_tab_pill.dart';
import 'coupons_tab_thumb.dart';

/// Segmented pill tabs of My coupons (Available / Used / Expired): equal
/// slots sharing the row, one dark thumb gliding under the selected one.
/// Kept in sync with the page's [controller], so swiping the lists drags the
/// thumb along too.
class CouponsTabBar extends StatelessWidget {
  const CouponsTabBar({
    super.key,
    required this.controller,
    required this.labels,
    required this.counts,
  });

  final TabController controller;
  final List<String> labels;
  final List<int> counts;

  static const double _height = AppSize.s44;
  static const double _gap = AppSpacing.s8;

  @override
  Widget build(BuildContext context) {
    final animation = controller.animation;
    if (animation == null) return const SizedBox.shrink();
    final duration = MotionGuard.duration(context, AppMotion.page);
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = labels.length;
          final pillWidth = (constraints.maxWidth - _gap * (count - 1)) / count;
          return Stack(
            children: [
              CouponsTabThumb(
                animation: animation,
                pillWidth: pillWidth,
                gap: _gap,
              ),
              for (var i = 0; i < count; i++)
                PositionedDirectional(
                  start: i * (pillWidth + _gap),
                  width: pillWidth,
                  top: 0,
                  bottom: 0,
                  child: CouponsTabPill(
                    label: labels[i],
                    count: counts[i],
                    index: i,
                    animation: animation,
                    onTap: () => controller.animateTo(
                      i,
                      duration: duration,
                      curve: AppMotion.emphasizedDecelerate,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
