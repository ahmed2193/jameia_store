import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import 'coupon_fade.dart';

/// Cream pill with a small glyph and a condition of the coupon ("Min KD
/// 5.000", "Valid till 2026-12-31"). [faded] paints it in the spent-coupon
/// greys ([CouponFade]).
class CouponInfoChip extends StatelessWidget {
  const CouponInfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.faded = false,
  });

  final IconData icon;
  final String label;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CouponFade.of(AppColors.accent3Light, faded: faded),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroIcon(
              icon,
              size: AppSize.s12,
              color: CouponFade.of(AppColors.accent3Dark, faded: faded),
            ),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: CouponFade.of(AppColors.voucherBrown, faded: faded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
