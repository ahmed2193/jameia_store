import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_savings.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_info_sheet.dart';
import 'checkout_receipt_row.dart';

/// "Subtotal ⓘ": the goods at today's prices. When some lines are on sale,
/// a grey "Promo items: KD x off applied" line and the struck list-price
/// subtotal sit under it. Both come from the (projected) lines, so they stay
/// while the cart re-prices. The ⓘ opens a short explanation.
class CheckoutReceiptSubtotalRow extends StatelessWidget {
  const CheckoutReceiptSubtotalRow({super.key});

  @override
  Widget build(BuildContext context) {
    // The same quoted fee every savings reader passes, so they all hit the
    // one cached `CartSavings` of the cart snapshot.
    final quotedFee = context.select<CheckoutCubit, int?>(
      (cubit) => cubit.state.selection?.deliveryFeeFils,
    );
    final figures = context
        .select<
          CartCubit,
          ({
            double subtotalKd,
            bool promo,
            double promoKd,
            double listSubtotalKd,
          })
        >((cubit) {
          final cart = cubit.state.cart;
          final savings = CartSavings.of(
            cart,
            quotedDeliveryFeeFils: quotedFee,
          );
          return (
            subtotalKd: cart.totals.subtotalKd,
            promo: savings.itemSavingsFils > 0,
            promoKd: savings.itemSavingsKd,
            listSubtotalKd: savings.listSubtotalKd,
          );
        });
    return CheckoutReceiptRow(
      label: 'checkout.summary_subtotal'.tr(),
      // Its own node, so the ⓘ is announced as a button with the sheet's
      // title and keeps the tap action.
      labelTrailing: Semantics(
        container: true,
        button: true,
        label: 'checkout.subtotal_info_title'.tr(),
        child: InkResponse(
          radius: AppSize.s14,
          onTap: () => CheckoutInfoSheet.show(
            context,
            title: 'checkout.subtotal_info_title'.tr(),
            body: 'checkout.subtotal_info_body'.tr(),
          ),
          child: const Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s4),
            child: Icon(
              Icons.info_outline_rounded,
              size: AppSize.s14,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ),
      value: HeroMoneyText(kd: figures.subtotalKd),
      note: figures.promo
          ? 'checkout.receipt_promo_items'.tr(
              namedArgs: {'amount': Formatters.price(figures.promoKd)},
            )
          : null,
      struck: figures.promo
          ? HeroMoneyText(
              kd: figures.listSubtotalKd,
              strike: true,
              color: AppColors.tertiaryText,
            )
          : null,
    );
  }
}
