import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/second_clock_scope.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../cubit/checkout_offers_cubit.dart';
import '../widgets/vouchers/checkout_vouchers_body.dart';

/// "Coupons & offers" of the open checkout (`Routes.checkoutVouchers`):
/// coupon code entry, the applied coupon and the cart's offers. [branchId]
/// is the serving branch (offers limited to other branches are left out).
///
/// The page reads the store's offers itself (cached, so it is usually
/// instant) and holds one second clock for every countdown on it: one
/// timer, ticking only while the page is on stage.
class CheckoutVouchersPage extends StatelessWidget {
  const CheckoutVouchersPage({super.key, this.branchId});

  final String? branchId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheckoutOffersCubit>(
      create: (_) => sl<CheckoutOffersCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.smallBackground,
        appBar: HeroTitleBar(title: 'checkout.savings_coupons'.tr()),
        body: SecondClockScope(child: CheckoutVouchersBody(branchId: branchId)),
      ),
    );
  }
}
