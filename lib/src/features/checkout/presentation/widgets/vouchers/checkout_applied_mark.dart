import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// "✓ Applied" on a ticket the cart already applied (the coupon, an offer):
/// a green check and the word, read as one.
class CheckoutAppliedMark extends StatelessWidget {
  const CheckoutAppliedMark({super.key});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeroIcon(
            HeroIcons.check,
            size: AppSize.s16,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: AppSpacing.s4),
          Text(
            'checkout.applied'.tr(),
            maxLines: 1,
            style: AppTextStyles.label.copyWith(color: AppColors.primaryText),
          ),
        ],
      ),
    );
  }
}
