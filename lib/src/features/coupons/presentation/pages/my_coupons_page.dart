import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/coupons_cubit.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../widgets/coupons_state_switch.dart';
import '../widgets/my_coupons/coupons_history_link.dart';
import '../widgets/my_coupons/my_coupons_content.dart';

/// My coupons: the savings card, the Available / Used / Expired pill tabs and
/// the coupon tickets; "History" opens the used + expired feed and "Use"
/// returns to the shell.
class MyCouponsPage extends StatelessWidget {
  const MyCouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponsCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: HeroTitleBar(
          title: 'coupons.my_coupons'.tr(),
          actions: const [CouponsHistoryLink()],
        ),
        body: CouponsStateSwitch(
          loaded: (_, buckets) => MyCouponsContent(buckets: buckets),
        ),
      ),
    );
  }
}
