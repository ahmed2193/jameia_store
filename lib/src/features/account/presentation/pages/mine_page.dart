import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/account_cubit.dart';
import '../widgets/mine/mine_body.dart';

/// Jameia "Mine" (account) tab: the collapsing profile header (sign-in
/// prompt for a guest), the quick stats (wallet · points · coupons ·
/// favourites), the invite banner, the menu cards (orders, addresses,
/// coupons, wallet, loyalty points, Jm3eia Pro, invite friends,
/// notifications, the assistant, customer service, settings, about) and the
/// delivery code, on the `mediumBackground` page. The overview cubit is
/// created — and loads — the first time the tab is opened.
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountCubit>(),
      child: const Scaffold(
        backgroundColor: AppColors.mediumBackground,
        body: MineBody(),
      ),
    );
  }
}
