import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_confirm_dialog.dart';
import 'pro_cta_button.dart';

/// The paywall's CTA for the selected plan: a guest goes to sign-in (`go`, so
/// the page is rebuilt for the new session); a customer confirms, then
/// subscribes. Cannot fire twice: disabled while any money action runs. The
/// label flips to the new price when the customer switches plans.
class ProJoinButton extends StatelessWidget {
  const ProJoinButton({super.key});

  static String _label(ProMembershipState state) {
    final plan = state.selectedPlan;
    if (state.isSignedOut) return 'pro.sign_in_to_join'.tr();
    if (plan == null) return 'pro.subscribe'.tr();
    // "/ month" and "/ year" only describe a single-period plan; the price
    // line above the CTA states any other cadence ("Billed every 3 months").
    final key = plan.intervalCount != 1
        ? 'pro.join_other'
        : switch (plan.interval) {
            ProBillingInterval.month => 'pro.join_month',
            ProBillingInterval.year => 'pro.join_year',
            ProBillingInterval.other => 'pro.join_other',
          };
    return key.tr(namedArgs: {'price': Formatters.price(plan.priceKd)});
  }

  Future<void> _join(BuildContext context, ProPlan plan) async {
    final cubit = context.read<ProMembershipCubit>();
    if (cubit.state.isSignedOut) {
      context.go(Routes.login);
      return;
    }
    final confirmed = await showJameiaDialog<bool>(
      context,
      barrierLabel: 'pro.subscribe'.tr(),
      pageBuilder: (_) => ProConfirmDialog(
        title: 'pro.confirm_subscribe_title'.tr(namedArgs: {'plan': plan.name}),
        message: 'pro.confirm_subscribe_body'.tr(
          namedArgs: {'price': Formatters.price(plan.priceKd)},
        ),
        confirmLabel: 'pro.subscribe'.tr(),
      ),
    );
    if (confirmed ?? false) await cubit.subscribe(plan.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProMembershipCubit, ProMembershipState>(
      buildWhen: (previous, current) =>
          previous.isSignedOut != current.isSignedOut ||
          previous.selectedPlan != current.selectedPlan ||
          previous.submittingPlanId != current.submittingPlanId ||
          previous.isBusy != current.isBusy,
      builder: (context, state) {
        final plan = state.selectedPlan;
        return ProCtaButton(
          label: _label(state),
          loading: plan != null && state.submittingPlanId == plan.id,
          enabled: !state.isBusy && plan != null,
          onPressed: plan == null ? null : () => _join(context, plan),
        );
      },
    );
  }
}
