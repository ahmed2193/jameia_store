import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../cubit/loyalty_rewards_cubit.dart';
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
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: HeroTitleBar(title: 'loyalty.rewards_title'.tr()),
        body: const RewardsFailureListener(child: RewardsBody()),
      ),
    );
  }
}
