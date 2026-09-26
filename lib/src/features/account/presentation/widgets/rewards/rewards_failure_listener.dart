import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../cubit/loyalty_rewards_cubit.dart';
import '../../cubit/loyalty_rewards_state.dart';

/// Toasts a failed pull-to-refresh (the tiers stay on screen). A failed
/// first load is rendered inline by the body instead.
class RewardsFailureListener extends StatelessWidget {
  const RewardsFailureListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoyaltyRewardsCubit, LoyaltyRewardsState>(
      listenWhen: (_, current) => current.isLoaded && current.failure != null,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showJameiaSnackBar(context, failure.localizedMessage);
      },
      child: child,
    );
  }
}
