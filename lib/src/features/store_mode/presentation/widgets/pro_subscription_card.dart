import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../domain/entities/pro_membership.dart';

/// The customer's current Pro subscription: plan, when it renews (or ends
/// after a cancellation) and the cancel action.
class ProSubscriptionCard extends StatelessWidget {
  const ProSubscriptionCard({
    super.key,
    required this.subscription,
    required this.isCancelling,
    required this.canAct,
    required this.onCancel,
  });

  final ProSubscription subscription;
  final bool isCancelling;

  /// `false` while another action is in flight.
  final bool canAct;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final periodEnd = subscription.currentPeriodEnd;
    final date = periodEnd == null
        ? ''
        : DateFormat.yMMMd(context.locale.languageCode)
              .format(periodEnd.toLocal());
    final statusKey = !subscription.isActive
        ? 'pro.status_inactive'
        : subscription.cancelAtPeriodEnd
        ? 'pro.ends_on'
        : 'pro.renews_on';
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        0,
        AppSpacing.s12,
        AppSpacing.s12,
      ),
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.brandLightBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pro.your_plan'.tr(namedArgs: {'plan': subscription.planName}),
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            statusKey.tr(namedArgs: {'date': date}),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          if (subscription.canCancel) ...[
            const SizedBox(height: AppSpacing.s8),
            if (isCancelling)
              const AppLoader()
            else
              TextButton(
                onPressed: canAct ? onCancel : null,
                child: Text(
                  'pro.cancel_renewal'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
