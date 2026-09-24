import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/account_cubit.dart';
import '../widgets/mine/mine_body.dart';

/// Jameia "Mine" (account) tab — `mach_pro_sailor_c_mine`: the session-aware
/// header, quick stats (coupons · wallet · favourites), invite banner, menu
/// (orders, addresses, wallet, loyalty points, Jm3eia Pro, coupons, …) and
/// the delivery code, on the `mediumBackground` page.
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
