import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/coupons_cubit.dart';
import '../widgets/coupons_app_bar.dart';
import '../widgets/coupons_state_switch.dart';
import '../widgets/history_coupons/history_coupons_list.dart';

/// Coupon history: the read-only feed of used and expired coupons, grouped,
/// faded under their stamps.
class HistoryCouponsPage extends StatelessWidget {
  const HistoryCouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponsCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CouponsAppBar(title: 'coupons.coupon_history'.tr()),
        body: CouponsStateSwitch(
          loaded: (_, buckets) => HistoryCouponsList(buckets: buckets),
        ),
      ),
    );
  }
}
