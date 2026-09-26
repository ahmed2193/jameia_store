import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/loyalty_rewards_cubit.dart';
import '../widgets/rewards/rewards_app_bar.dart';
import '../widgets/rewards/rewards_body.dart';
import '../widgets/rewards/rewards_failure_listener.dart';

/// Loyalty → Rewards: the points balance and fixed redemption tiers derived
/// from the store's programme (`GET /v1/init` + `GET /v1/account/loyalty`).
/// A ready tier is spent on the current basket (`POST /v1/cart/loyalty`)
/// through the app-global cart. Signed-in only.
class LoyaltyRewardsPage extends StatelessWidget {
  const LoyaltyRewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoyaltyRewardsCubit>()..load(),
      child: const Scaffold(
        backgroundColor: AppColors.white,
        appBar: RewardsAppBar(),
        body: RewardsFailureListener(child: RewardsBody()),
      ),
    );
  }
}
