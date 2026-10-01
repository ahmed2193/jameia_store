import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_savings_figure.dart';

/// "Coupons & offers": the voucher disc, the title and, under it, what the
/// coupon and the offers save ([CheckoutSavingsFigure]). A tap opens the
/// "Coupons & offers" page with the serving branch, so that page can leave
/// out offers limited to other branches (a navigation row: no haptic).
class CheckoutCouponsRow extends StatelessWidget {
  const CheckoutCouponsRow({super.key});

  /// The voucher disc (visual spec: 25 dp).
  static const double discSize = AppSize.s25;

  @override
  Widget build(BuildContext context) {
    return HeroListRow(
      dense: true,
      leading: const HeroSvgGlyph.art(
        HeroAssets.checkoutVoucherDisc,
        size: discSize,
      ),
      title: 'checkout.savings_coupons'.tr(),
      subtitleWidget: const CheckoutSavingsFigure(),
      onTap: () => context.push(
        Routes.checkoutVouchers,
        extra: context.read<CheckoutCubit>().state.selection?.branchId,
      ),
    );
  }
}
