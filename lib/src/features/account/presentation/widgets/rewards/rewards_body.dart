import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/loyalty_rewards_cubit.dart';
import '../../cubit/loyalty_rewards_state.dart';
import 'rewards_content.dart';

/// Switches the Rewards screen on the cubit status: loader, sign-in prompt
/// (the points route answered 401), error + retry ("Checking your
/// connection…" → "No connection" for a lost one; a returning connection
/// loads a failed screen again), "not available" when the
/// store runs no programme, or the tiers — each swap fades through
/// ([FadeThroughSwitcher]); a refresh of the tiers updates in place.
class RewardsBody extends StatelessWidget {
  const RewardsBody({super.key});

  static const Object _signedOutKey = #signedOut;
  static const Object _unavailableKey = #unavailable;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<LoyaltyRewardsCubit>().onReconnected(),
      child: BlocBuilder<LoyaltyRewardsCubit, LoyaltyRewardsState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.rewards != current.rewards,
        builder: (context, state) => FadeThroughSwitcher(
          stateKey: switch (state.status) {
            LoyaltyRewardsStatus.initial => LoyaltyRewardsStatus.loading,
            LoyaltyRewardsStatus.error when state.isSignedOut => _signedOutKey,
            LoyaltyRewardsStatus.loaded when !state.rewards.isAvailable =>
              _unavailableKey,
            final status => status,
          },
          child: switch (state.status) {
            LoyaltyRewardsStatus.initial ||
            LoyaltyRewardsStatus.loading => const AppLoader(),
            LoyaltyRewardsStatus.error when state.isSignedOut =>
              HeroStateView.signedOut(message: 'loyalty.sign_in_prompt'.tr()),
            LoyaltyRewardsStatus.error => FailureView(
              failure: state.failure,
              onRetry: () => context.read<LoyaltyRewardsCubit>().load(),
            ),
            LoyaltyRewardsStatus.loaded when !state.rewards.isAvailable =>
              HeroStateView(
                message: 'loyalty.rewards_unavailable'.tr(),
                art: HeroAssets.stateUnavailable,
              ),
            LoyaltyRewardsStatus.loaded => RewardsContent(
              rewards: state.rewards,
            ),
          },
        ),
      ),
    );
  }
}
