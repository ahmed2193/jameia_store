import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'coupon_select_check.dart';

/// "Don't use a coupon" row of the checkout picker; selected, it lifts and
/// wears the same accent ring as a picked coupon.
class OrderNoCouponOption extends StatelessWidget {
  const OrderNoCouponOption({
    super.key,
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  static const double _lift = AppSpacing.s4;
  static const double _disc = AppSize.s40;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        const SizedBox.square(
          dimension: _disc,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.smallBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.do_not_disturb_on_outlined,
              size: AppSize.s20,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'coupons.dont_use'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'coupons.dont_use_hint'.tr(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        CouponSelectCheck(selected: selected),
      ],
    );
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: selected ? 1 : 0),
          duration: MotionGuard.duration(context, AppMotion.medium),
          curve: AppMotion.emphasizedDecelerate,
          child: content,
          builder: (_, t, child) => Transform.translate(
            offset: Offset(0, -_lift * t),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.r3),
                boxShadow: AppShadows.low,
                border: Border.all(
                  color: Color.lerp(AppColors.divider, kJameiaPillPin, t)!,
                  width: lerpDouble(AppSize.s1, AppSize.s2, t)!,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
