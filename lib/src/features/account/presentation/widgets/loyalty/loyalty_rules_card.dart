import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/loyalty_program.dart';
import 'loyalty_rule_row.dart';

/// "How it works": earn rate, what a point is worth, the redemption minimum
/// and the expiry — each line only when the store sets it — on a white card
/// with a hairline border.
class LoyaltyRulesCard extends StatelessWidget {
  const LoyaltyRulesCard({super.key, required this.program});

  final LoyaltyProgram program;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r3),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'loyalty.how_it_works'.tr(),
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.primaryText,
                  ),
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
                    namedArgs: {
                      'amount': Formatters.price(program.pointValueKd),
                    },
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
        ),
      ),
    );
  }
}
