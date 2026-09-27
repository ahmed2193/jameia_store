import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../cubit/pro_membership_cubit.dart';
import 'pro_member_status.dart';
import 'pro_plan_price.dart';

/// Cream card under the hero: greets the customer by name, then either their
/// membership (a member: the member card) or the selected plan's price per
/// month. A lapsed member is welcomed back and told when the membership
/// ended. Rises into view the first time it scrolls on screen.
class ProGreetingCard extends StatelessWidget {
  const ProGreetingCard({super.key});

  static String _greeting(ProMembershipEntity membership, String name) {
    if (membership.standing == ProStanding.lapsed) {
      return name.isEmpty
          ? 'pro.lapsed_greeting_guest'.tr()
          : 'pro.lapsed_greeting'.tr(namedArgs: {'name': name});
    }
    return name.isEmpty
        ? 'pro.greeting_guest'.tr()
        : 'pro.greeting_name'.tr(namedArgs: {'name': name});
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthSessionCubit, String>(
      (cubit) =>
          cubit.state.isSignedIn ? cubit.state.customer?.givenName ?? '' : '',
    );
    final membership = context.select<ProMembershipCubit, ProMembershipEntity>(
      (cubit) => cubit.state.membership,
    );
    final lapsed = membership.standing == ProStanding.lapsed;
    final ended = Formatters.date(
      context.locale.languageCode,
      membership.periodEnd,
    );
    return ScrollReveal(
      child: Container(
        margin: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
        ),
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: kHeroPromoCream,
          borderRadius: BorderRadius.circular(AppRadius.r2),
        ),
        child: Column(
          children: [
            Text(
              _greeting(membership, name),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge.copyWith(
                fontSize: AppSize.font20,
                fontWeight: AppTextStyles.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            if (lapsed) ...[
              Text(
                ended.isEmpty
                    ? 'pro.lapsed_notice_undated'.tr()
                    : 'pro.lapsed_notice'.tr(namedArgs: {'date': ended}),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            if (membership.hasBenefits)
              const ProMemberStatus()
            else
              const ProPlanPrice(),
          ],
        ),
      ),
    );
  }
}
