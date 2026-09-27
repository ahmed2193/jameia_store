import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_cancel_renewal_button.dart';
import 'pro_ending_notice.dart';
import 'pro_member_card.dart';

/// A member's side of the greeting card: "You're a Pro member", their Pro
/// member card (plan, renewal / benefits date) and, while the membership
/// still renews, the cancel action — once cancelled, the notice that it
/// will not renew and until when the perks stay on.
class ProMemberStatus extends StatelessWidget {
  const ProMemberStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ProMembershipCubit,
      ProMembershipState,
      ProSubscription?
    >(
      selector: (state) => state.subscription,
      builder: (context, subscription) {
        if (subscription == null) return const SizedBox.shrink();
        return Column(
          children: [
            Text(
              'pro.member_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.subheadingLarge.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            ProMemberCard(subscription: subscription),
            if (subscription.canCancel) ...[
              const SizedBox(height: AppSpacing.s8),
              const ProCancelRenewalButton(),
            ] else if (subscription.cancelAtPeriodEnd) ...[
              const SizedBox(height: AppSpacing.s12),
              ProEndingNotice(periodEnd: subscription.currentPeriodEnd),
            ],
          ],
        );
      },
    );
  }
}
