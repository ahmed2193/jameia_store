import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/press_scale.dart';
import 'coupons_tab_badge.dart';

/// One coupon tab: an outlined, see-through pill whose label turns white as
/// the sliding thumb (following the tab controller's [animation]) arrives
/// under it, with the bucket's [count] in an orange bubble when non-zero.
class CouponsTabPill extends StatelessWidget {
  const CouponsTabPill({
    super.key,
    required this.label,
    required this.count,
    required this.index,
    required this.animation,
    required this.onTap,
  });

  final String label;
  final int count;
  final int index;
  final Animation<double> animation;
  final VoidCallback onTap;

  static const double _selectedFrom = 0.5;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // 1 while the thumb sits here, fading to 0 one slot away.
        final t = (1 - (animation.value - index).abs()).clamp(0.0, 1.0);
        final selected = t >= _selectedFrom;
        return Semantics(
          button: true,
          selected: selected,
          child: PressScale(
            onTap: onTap,
            haptic: selected ? null : HapticKind.selection,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 1 - t),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s8,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: AppTextStyles.bold,
                              color: Color.lerp(
                                AppColors.primaryText,
                                AppColors.white,
                                t,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: AppSpacing.s6),
                        CouponsTabBadge(count: count),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
