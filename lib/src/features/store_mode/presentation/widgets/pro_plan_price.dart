import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';

/// The selected plan's pitch for a non-member: what Pro saves, the price per
/// month in big violet (only its digits roll, up or down, when the customer
/// switches plans — the app's one money motion), and how it is billed. A plan
/// switch lands here a beat after the tabs' thumb moved (backlog B2-03).
class ProPlanPrice extends StatelessWidget {
  const ProPlanPrice({super.key});

  /// The figure the headline shows: per month, or the plain price for an
  /// interval the app cannot spread.
  static double _headlineKd(ProPlan plan) =>
      plan.interval == ProBillingInterval.other
      ? plan.priceKd
      : plan.monthlyPriceKd ?? plan.priceKd;

  /// The headline around the written-out [amount].
  static String _headline(ProBillingInterval interval, String amount) =>
      (interval == ProBillingInterval.other
              ? 'pro.per_period'
              : 'pro.per_month')
          .tr(namedArgs: {'price': Formatters.priceOf(amount)});

  static String _amount(num kd) => Formatters.amount(kd.toDouble());

  /// `null` for an interval the app does not know (no billing cadence to
  /// describe).
  static String? _billing(ProPlan plan) {
    if (plan.interval == ProBillingInterval.other) return null;
    final price = Formatters.price(plan.priceKd);
    if (plan.interval == ProBillingInterval.year && plan.intervalCount == 1) {
      return 'pro.billed_yearly'.tr(namedArgs: {'price': price});
    }
    if (plan.isMultiMonth) {
      return 'pro.billed_every'.tr(
        namedArgs: {'count': '${plan.months}', 'price': price},
      );
    }
    return 'pro.billed_monthly'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProMembershipCubit, ProMembershipState>(
      buildWhen: (previous, current) =>
          previous.selectedPlan != current.selectedPlan ||
          previous.program.perks.freeDelivery !=
              current.program.perks.freeDelivery,
      builder: (context, state) => DeferredValue<ProPlan?>(
        value: state.selectedPlan,
        delay: MotionBeat.second,
        deferWhen: (shown, next) => shown != null && next != null,
        builder: (context, plan) {
          if (plan == null) return const SizedBox.shrink();
          final billing = _billing(plan);
          final interval = plan.interval;
          return Column(
            children: [
              Text(
                state.program.perks.freeDelivery
                    ? 'pro.greeting_free_delivery'.tr()
                    : 'pro.greeting_generic'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.subheadingLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              RollingNumberText(
                value: _headlineKd(plan),
                format: _amount,
                text: (amount) => _headline(interval, amount),
                textAlign: TextAlign.center,
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: AppSize.font30,
                  height: AppSize.lh1_2,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.accentViolet,
                ),
              ),
              if (billing != null) ...[
                const SizedBox(height: AppSpacing.s4),
                FlipValue(
                  flipKey: billing,
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    billing,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
