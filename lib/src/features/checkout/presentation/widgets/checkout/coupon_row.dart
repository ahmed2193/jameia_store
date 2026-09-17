import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/coupon_entity.dart';

/// Coupon row: real Jameia coupon icon, red "1 available" badge.
/// Style from css.json ce3dc6: padding:16dp 12dp, row, space-between.
class CouponRow extends StatelessWidget {
  const CouponRow({
    super.key,
    required this.onTap,
    this.selected,
    this.discount = 0,
    this.availableCount = 0,
  });
  final VoidCallback onTap;

  /// The applied coupon, or null when none is selected.
  final CouponEntity? selected;

  /// Discount the applied coupon currently yields (0 when its min-spend gate is
  /// not yet met).
  final double discount;

  /// How many coupons are available to apply.
  final int availableCount;

  /// Trailing badge — green discount when a coupon is applied and active, an
  /// amber "Min spend" hint when applied but below its threshold, else the red
  /// "N available" count.
  Widget _badge() {
    if (selected != null && discount > 0) {
      return _pill(
        '- ${Formatters.price(discount)}',
        AppColors.freeDeliveryFgOnLight, // freeDelivery green
      );
    }
    if (selected != null) {
      return _pill(
        'checkout.coupon_min'.tr(
          namedArgs: {'amount': Formatters.price(selected!.minSpend)},
        ),
        AppColors.couponAmberHint, // amber hint
      );
    }
    return _pill(
      availableCount > 0
          ? 'checkout.coupons_available'.tr(
              namedArgs: {'count': '$availableCount'},
            )
          : 'checkout.coupons_none'.tr(),
      AppColors.couponBadgeRed, // ga867e badge red
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.s6,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.r5),
    ),
    child: Text(
      text,
      style: AppTextStyles.captionSmall.copyWith(
        color: AppColors.white,
        fontWeight: AppTextStyles.medium,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            // Real Jameia coupon icon
            Image.asset(
              JameiaAssets.couponIcon,
              width: 22,
              height: 22,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.confirmation_num_rounded,
                size: 20,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Text('checkout.coupons_title'.tr(), style: AppTextStyles.bodyLarge),
            const Spacer(),
            _badge(),
            const SizedBox(width: AppSpacing.s4),
            const Icon(
              JameiaIcons.arrowRight,
              color: AppColors.tertiaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
