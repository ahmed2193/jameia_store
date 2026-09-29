import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/after_arrival.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/light_sweep.dart';

/// Orange "Use" pill of an available coupon: it dips with a tap haptic when
/// pressed, and while [shimmers] a soft light band glides across it now and
/// then (a painted gradient, no GIF) — from once its ticket has landed
/// ([AfterArrival], backlog B2-03).
class CouponUseButton extends StatelessWidget {
  const CouponUseButton({
    super.key,
    required this.onPressed,
    this.shimmers = false,
  });

  final VoidCallback onPressed;
  final bool shimmers;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );
  static const double _glintAlpha = 0.5;

  /// The tap target's minimum height; the pill itself stays slim and
  /// centred in it (PressScale's opaque hit test covers the whole box).
  static const double _minTarget = AppSize.s44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onPressed,
        haptic: HapticKind.tap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minTarget),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: _radius,
                child: AfterArrival(
                  builder: (context, landed) => LightSweep(
                    active: shimmers && landed,
                    peakAlpha: _glintAlpha,
                    borderRadius: _radius,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        borderRadius: _radius,
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.centerStart,
                          end: AlignmentDirectional.centerEnd,
                          colors: [AppColors.accent3, kHeroPillPin],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s14,
                          vertical: AppSpacing.s6,
                        ),
                        child: Text(
                          'coupons.use'.tr(),
                          maxLines: 1,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
