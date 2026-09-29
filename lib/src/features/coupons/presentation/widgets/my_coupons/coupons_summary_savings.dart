import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import 'coupons_ready_pill.dart';

/// Text side of the savings card: "Save up to", the total (there at once on
/// open, rolling only on a real change) and how many coupons are ready.
class CouponsSummarySavings extends StatelessWidget {
  const CouponsSummarySavings({
    super.key,
    required this.savings,
    required this.ready,
  });

  /// KD the available coupons add up to.
  final double savings;
  final int ready;

  static const double _mutedAlpha = 0.88;
  static final Color _muted = AppColors.white.withValues(alpha: _mutedAlpha);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'coupons.save_up_to'.tr(),
          style: AppTextStyles.subheadingMedium.copyWith(color: _muted),
        ),
        const SizedBox(height: AppSpacing.s2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: HeroMoneyText(
            kd: savings,
            rolling: true,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: AppSize.font30,
              height: AppSize.lh1_2,
              fontWeight: AppTextStyles.bold,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        CouponsReadyPill(count: ready),
      ],
    );
  }
}
