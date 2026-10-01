import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/login_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_cta_button.dart';

/// The paywall's CTA for the selected plan: a guest goes to sign-in (`go`, so
/// the page is rebuilt for the new session, and comes back here once signed
/// in); a customer confirms, then subscribes — a lapsed member "rejoins".
/// Cannot fire twice: disabled while any money action runs. The label flips
/// to the new price a beat after the customer switches plans (backlog B2-03:
/// the tabs' thumb answers first; the button acts on the chosen plan at
/// once, and its confirmation names it).
class ProJoinButton extends StatelessWidget {
  const ProJoinButton({super.key});

  static String _label(ProMembershipState state, ProPlan? plan) {
    if (state.isSignedOut) return 'pro.sign_in_to_join'.tr();
    if (plan == null) return 'pro.subscribe'.tr();
    // "/ month" and "/ year" only describe a single-period plan; the price
    // line above the CTA states any other cadence ("Billed every 3 months").
    final interval = plan.intervalCount != 1
        ? ProBillingInterval.other
        : plan.interval;
    // A lapsed member rejoins; everyone else joins.
    final key = state.isLapsed
        ? switch (interval) {
            ProBillingInterval.month => 'pro.rejoin_month',
            ProBillingInterval.year => 'pro.rejoin_year',
            ProBillingInterval.other => 'pro.rejoin_other',
          }
        : switch (interval) {
            ProBillingInterval.month => 'pro.join_month',
            ProBillingInterval.year => 'pro.join_year',
            ProBillingInterval.other => 'pro.join_other',
          };
    return key.tr(namedArgs: {'price': Formatters.price(plan.priceKd)});
  }

  Future<void> _join(BuildContext context, ProPlan plan) async {
    final cubit = context.read<ProMembershipCubit>();
    if (cubit.state.isSignedOut) {
      // Back on this page once signed in, rebuilt for the new session.
      context.go(
        Routes.login,
        extra: const LoginArgs(returnTo: Routes.proMembership),
      );
      return;
    }
    final confirmed = await showHeroConfirmDialog(
      context,
      title: 'pro.confirm_subscribe_title'.tr(namedArgs: {'plan': plan.name}),
      message: 'pro.confirm_subscribe_body'.tr(
        namedArgs: {'price': Formatters.price(plan.priceKd)},
      ),
      icon: HeroIcons.crown,
      confirmLabel: 'pro.subscribe'.tr(),
    );
    if (confirmed) await cubit.subscribe(plan.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProMembershipCubit, ProMembershipState>(
      buildWhen: (previous, current) =>
          previous.isSignedOut != current.isSignedOut ||
          previous.isLapsed != current.isLapsed ||
          previous.selectedPlan != current.selectedPlan ||
          previous.submittingPlanId != current.submittingPlanId ||
          previous.isBusy != current.isBusy,
      builder: (context, state) {
        final plan = state.selectedPlan;
        return DeferredValue<ProPlan?>(
          value: plan,
          delay: MotionBeat.second,
          deferWhen: (shown, next) => shown != null && next != null,
          builder: (context, shown) => ProCtaButton(
            label: _label(state, shown),
            holding: plan != null && state.submittingPlanId == plan.id,
            enabled: !state.isBusy && plan != null,
            onPressed: plan == null ? null : () => _join(context, plan),
          ),
        );
      },
    );
  }
}
