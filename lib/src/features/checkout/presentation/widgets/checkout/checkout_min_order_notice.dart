import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';

/// Under the receipt while the basket is below the store's minimum order:
/// "Add KD x to reach the minimum order" (`checkout.receipt_min_order`, the
/// server's minimum) in a warning colour. The bar's pinned reason says the
/// same with the cart's own words (`cart.block_min_order`).
class CheckoutMinOrderNotice extends StatelessWidget {
  const CheckoutMinOrderNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final notice = context.select<CartCubit, ({bool below, double shortKd})>((
      cubit,
    ) {
      final totals = cubit.state.cart.totals;
      return (below: !totals.meetsMinOrder, shortKd: totals.shortfallKd);
    });
    return CollapseReveal(
      visible: notice.below,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s4,
          AppSpacing.s8,
          AppSpacing.s4,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeroIcon(
              HeroIcons.info,
              size: AppSize.s16,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.s6),
            Expanded(
              child: Text(
                'checkout.receipt_min_order'.tr(
                  namedArgs: {'amount': Formatters.price(notice.shortKd)},
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.errorDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
