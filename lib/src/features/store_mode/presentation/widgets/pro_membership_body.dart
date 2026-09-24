import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_confirm_dialog.dart';
import 'pro_perks_card.dart';
import 'pro_plan_tile.dart';
import 'pro_subscription_card.dart';

/// Body of the Pro page: loader → perks, the current subscription, the plans;
/// "programme unavailable" when the store switched Pro off; error + retry
/// (offline = the error view). A guest sees the plans; subscribing leads to
/// sign-in (`go`, so the page is rebuilt for the new session).
class ProMembershipBody extends StatelessWidget {
  const ProMembershipBody({super.key});

  Future<void> _subscribe(BuildContext context, ProPlan plan) async {
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

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<ProMembershipCubit>();
    final confirmed = await showJameiaDialog<bool>(
      context,
      barrierLabel: 'pro.cancel_renewal'.tr(),
      pageBuilder: (_) => ProConfirmDialog(
        title: 'pro.confirm_cancel_title'.tr(),
        message: 'pro.confirm_cancel_body'.tr(),
        confirmLabel: 'pro.cancel_renewal'.tr(),
        isDestructive: true,
      ),
    );
    if (confirmed ?? false) await cubit.cancelSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProMembershipCubit, ProMembershipState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.program != current.program ||
          previous.subscription != current.subscription ||
          previous.isBusy != current.isBusy ||
          previous.submittingPlanId != current.submittingPlanId,
      builder: (context, state) {
        final cubit = context.read<ProMembershipCubit>();
        switch (state.status) {
          case ProMembershipStatus.initial:
          case ProMembershipStatus.loading:
            return const AppLoader();
          case ProMembershipStatus.error:
            return ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: cubit.load,
            );
          case ProMembershipStatus.loaded:
            if (state.program.isUnavailable) {
              return BrandedRefresh(
                onRefresh: cubit.refresh,
                child: EmptyStateView(
                  message: 'pro.unavailable'.tr(),
                  icon: Icons.workspace_premium_outlined,
                ),
              );
            }
            final subscription = state.subscription;
            final plans = state.program.plans;
            return ColoredBox(
              color: AppColors.mediumBackground,
              child: BrandedRefresh(
                onRefresh: cubit.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.s24,
                  ),
                  children: [
                    ProPerksCard(
                      perks: state.program.perks,
                      isMember: state.isMember,
                    ),
                    if (subscription != null)
                      ProSubscriptionCard(
                        subscription: subscription,
                        isCancelling: state.isCancelling,
                        canAct: !state.isBusy,
                        onCancel: () => _cancel(context),
                      ),
                    for (final plan in plans)
                      ProPlanTile(
                        key: ValueKey(plan.id),
                        plan: plan,
                        isCurrent:
                            state.isMember && subscription?.planId == plan.id,
                        isSubmitting: state.submittingPlanId == plan.id,
                        isEnabled: !state.isBusy && !state.isMember,
                        onSubscribe: () => _subscribe(context, plan),
                      ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
