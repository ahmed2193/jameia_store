import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/pro_membership.dart';

/// One Pro plan: name, price per billing period and its subscribe button.
class ProPlanTile extends StatelessWidget {
  const ProPlanTile({
    super.key,
    required this.plan,
    required this.isCurrent,
    required this.isSubmitting,
    required this.isEnabled,
    required this.onSubscribe,
  });

  final ProPlan plan;

  /// The customer's active plan.
  final bool isCurrent;

  /// This plan's subscribe call is in flight.
  final bool isSubmitting;

  /// `false` while any action is in flight or the customer is already a member.
  final bool isEnabled;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final periodKey = switch (plan.interval) {
      ProBillingInterval.month => 'pro.per_month',
      ProBillingInterval.year => 'pro.per_year',
      ProBillingInterval.other => 'pro.per_period',
    };
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        0,
        AppSpacing.s12,
        AppSpacing.s8,
      ),
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isCurrent ? AppColors.primaryDark : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  periodKey.tr(
                    namedArgs: {
                      'price': Formatters.price(plan.priceKd),
                      'count': '${plan.intervalCount}',
                    },
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          SizedBox(
            width: AppSize.s120,
            child: AppButton(
              label: isCurrent ? 'pro.current_plan'.tr() : 'pro.subscribe'.tr(),
              height: AppSize.s40,
              enabled: isEnabled && !isCurrent,
              loading: isSubmitting,
              onPressed: onSubscribe,
            ),
          ),
        ],
      ),
    );
  }
}
