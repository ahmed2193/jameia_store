import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/loyalty_program.dart';
import 'loyalty_rule_row.dart';

/// "How it works": earn rate, what a point is worth, the redemption minimum
/// and the expiry — each line only when the store sets it.
class LoyaltyRulesCard extends StatelessWidget {
  const LoyaltyRulesCard({super.key, required this.program});

  final LoyaltyProgram program;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(
        start: AppSpacing.s16,
        end: AppSpacing.s16,
        bottom: AppSpacing.s16,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.mediumBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'loyalty.how_it_works'.tr(),
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          if (program.pointsPerKwd > 0)
            LoyaltyRuleRow(
              icon: Icons.shopping_bag_outlined,
              text: 'loyalty.earn_rate'.tr(
                namedArgs: {'n': '${program.pointsPerKwd}'},
              ),
            ),
          if (program.redemptionPerPoint > 0)
            LoyaltyRuleRow(
              icon: Icons.redeem_rounded,
              text: 'loyalty.redeem_rate'.tr(
                namedArgs: {'amount': Formatters.price(program.pointValueKd)},
              ),
            ),
          if (program.minRedeemPoints > 0)
            LoyaltyRuleRow(
              icon: Icons.flag_outlined,
              text: 'loyalty.min_redeem'.tr(
                namedArgs: {'min': '${program.minRedeemPoints}'},
              ),
            ),
          if (program.pointsExpire)
            LoyaltyRuleRow(
              icon: Icons.hourglass_bottom_rounded,
              text: 'loyalty.expiry'.tr(
                namedArgs: {'months': '${program.pointsExpireMonths}'},
              ),
            ),
        ],
      ),
    );
  }
}
