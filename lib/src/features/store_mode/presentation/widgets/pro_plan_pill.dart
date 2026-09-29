import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/pro_membership.dart';
import 'pro_save_badge.dart';

/// One plan tab: an outlined pill whose label turns white when the sliding
/// selection thumb (the tabs' `SegmentedThumbTrack`) sits under it, with the "Save N%"
/// chip overlapping its top edge when [savingPercent] > 0. The pill itself is
/// see-through, so the thumb gliding beneath stays visible. [onTap] is `null`
/// while a money action is in flight. The pill dips when pressed (the track
/// fires the selection haptic); its colours change over [AppMotion.fast].
class ProPlanPill extends StatelessWidget {
  const ProPlanPill({
    super.key,
    required this.plan,
    required this.selected,
    required this.savingPercent,
    required this.onTap,
  });

  static const double height = AppSize.s44;

  /// How far the saving chip rises above the pill's top edge.
  static const double _badgeLift = AppSize.s12;

  final ProPlan plan;
  final bool selected;
  final int savingPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.fast);
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        onTap: onTap,
        enabled: onTap != null,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.signature,
              height: height,
              alignment: Alignment.center,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected
                      ? AppColors.divider.withValues(alpha: 0)
                      : AppColors.divider,
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: duration,
                curve: AppMotion.signature,
                style: AppTextStyles.headingMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.primaryText,
                ),
                child: Text(
                  plan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (savingPercent > 0)
              Positioned(
                top: -_badgeLift,
                child: ProSaveBadge(percent: savingPercent),
              ),
          ],
        ),
      ),
    );
  }
}
