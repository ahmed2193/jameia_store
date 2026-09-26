import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/signed_out_view.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/loyalty_rewards_cubit.dart';
import '../../cubit/loyalty_rewards_state.dart';
import 'rewards_content.dart';

/// Switches the Rewards screen on the cubit status: loader, sign-in prompt
/// (the points route answered 401), error + retry, "not available" when the
/// store runs no programme, or the tiers.
class RewardsBody extends StatelessWidget {
  const RewardsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyRewardsCubit, LoyaltyRewardsState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.rewards != current.rewards,
      builder: (context, state) => switch (state.status) {
        LoyaltyRewardsStatus.initial ||
        LoyaltyRewardsStatus.loading => const AppLoader(),
        LoyaltyRewardsStatus.error when state.isSignedOut => SignedOutView(
          message: 'loyalty.sign_in_prompt'.tr(),
        ),
        LoyaltyRewardsStatus.error => ErrorView(
          message: state.failure?.localizedMessage,
          onRetry: () => context.read<LoyaltyRewardsCubit>().load(),
        ),
        LoyaltyRewardsStatus.loaded when !state.rewards.isAvailable =>
          EmptyStateView(
            message: 'loyalty.rewards_unavailable'.tr(),
            icon: Icons.card_giftcard_outlined,
          ),
        LoyaltyRewardsStatus.loaded => RewardsContent(rewards: state.rewards),
      },
    );
  }
}
