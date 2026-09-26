import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/jameia_bar_total.dart';
import '../../../../../core/widgets/jameia_bottom_bar.dart';
import '../../../../../core/widgets/jameia_submit_button.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_summary.dart';

/// Sticky footer: the total and "Place order". One tap places once; the
/// button waits while the cart still syncs or a destination is being
/// selected. The total stays mounted under the "—" so a re-quote rolls its
/// digits; the button turns into a check when the order is placed.
///
/// Placing empties the cart while this page is still on screen under the
/// tracking page's entrance, so the total freezes from then on: it keeps
/// the amount just placed instead of rolling down to zero. Only the check
/// still pops.
class CheckoutPlaceOrderBar extends StatelessWidget {
  const CheckoutPlaceOrderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final canPlace = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.canPlace,
    );
    final placing = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.isPlacing,
    );
    final placed = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.status == CheckoutStatus.placed,
    );
    final cartReady = context.select<CartCubit, bool>(
      (cubit) =>
          !cubit.state.isUpdating &&
          !cubit.state.isBusy &&
          cubit.state.cart.canCheckout,
    );
    final totalKd = context.select<CartCubit, double>(
      (cubit) => cubit.state.cart.totals.totalKd,
    );
    final quoted = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.selection != null,
    );
    return JameiaBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TickerMode(
            enabled: !placed,
            child: Row(
              children: [
                // The amount keeps its width; a long label at large text
                // ellipsizes instead.
                Expanded(
                  child: Text(
                    'checkout.summary_total'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.itemTitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                JameiaBarTotal(
                  kd: quoted ? totalKd : null,
                  placeholder: CheckoutSummary.unquoted,
                  style: AppTextStyles.groupTitle,
                  placeholderStyle: AppTextStyles.groupTitle.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          JameiaSubmitButton(
            label: placing
                ? 'checkout.placing'.tr()
                : 'checkout.place_order'.tr(),
            loading: placing,
            success: placed,
            successLabel: 'checkout.order_placed'.tr(),
            enabled: canPlace && cartReady,
            onPressed: () => context.read<CheckoutCubit>().placeOrder(),
          ),
        ],
      ),
    );
  }
}
