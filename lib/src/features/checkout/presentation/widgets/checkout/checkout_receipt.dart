import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/widgets/jameia_money_text.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_min_order_notice.dart';
import 'checkout_receipt_border.dart';
import 'checkout_receipt_delivery_row.dart';
import 'checkout_receipt_discount_row.dart';
import 'checkout_receipt_row.dart';
import 'checkout_receipt_subtotal_row.dart';
import 'checkout_receipt_total_row.dart';
import 'checkout_section.dart';

/// "Order totals": the server's figures on a scalloped receipt, in this
/// order — Subtotal, Delivery, then Express / Offers / Coupon / Points only
/// while they are not zero (each opens and closes in place), then Total —
/// and the minimum-order notice under the card. No VAT line: the API
/// carries none.
///
/// The rows add up to the total because the delivery line leaves the
/// express surcharge to its own line. Values are static; the bar's total is
/// the one that rolls.
class CheckoutReceipt extends StatelessWidget {
  const CheckoutReceipt({super.key});

  /// What an amount the server has not quoted yet reads as — here and in
  /// the place-order bar. No letters, so it reads the same in both locales.
  static const String unquoted = '—';

  /// From the card's edge to the first row: past the bites, then 10 dp of
  /// air (the rows add their own 6 dp).
  static const double _contentInset =
      CheckoutReceiptBorder.biteDepth + AppSpacing.s10;

  @override
  Widget build(BuildContext context) {
    final quoted = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.hasSelection,
    );
    final extras = context
        .select<
          CartCubit,
          ({
            bool express,
            double expressKd,
            bool offers,
            double offersKd,
            bool coupon,
            double couponKd,
            String code,
            bool points,
            double pointsKd,
            int pointsUsed,
          })
        >((cubit) {
          final cart = cubit.state.cart;
          final totals = cart.totals;
          return (
            express: totals.expressSurchargeFils > 0,
            expressKd: totals.expressSurchargeKd,
            offers: totals.offerDiscountFils > 0,
            offersKd: totals.offerDiscountKd,
            coupon: totals.couponDiscountFils > 0,
            couponKd: totals.couponDiscountKd,
            code: cart.coupon?.code ?? '',
            points: totals.loyaltyDiscountFils > 0,
            pointsKd: totals.loyaltyDiscountKd,
            pointsUsed: cart.loyalty.pointsApplied,
          );
        });
    return CheckoutSection(
      title: 'checkout.totals_title'.tr(),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            painter: const CheckoutReceiptBorder(
              color: AppColors.smallBackground,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
                vertical: _contentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CheckoutReceiptSubtotalRow(),
                  const CheckoutReceiptDeliveryRow(),
                  // The server's deliveryFee carries the surcharge; the
                  // delivery line shows the fee without it.
                  CollapseReveal(
                    visible: quoted && extras.express,
                    child: CheckoutReceiptRow(
                      label: 'checkout.summary_express'.tr(),
                      value: JameiaMoneyText(kd: extras.expressKd),
                    ),
                  ),
                  CheckoutReceiptDiscountRow(
                    visible: extras.offers,
                    label: 'checkout.receipt_offers'.tr(),
                    kd: extras.offersKd,
                  ),
                  CheckoutReceiptDiscountRow(
                    visible: extras.coupon,
                    label: 'checkout.receipt_coupon'.tr(
                      namedArgs: {'code': extras.code},
                    ),
                    kd: extras.couponKd,
                  ),
                  CheckoutReceiptDiscountRow(
                    visible: extras.points,
                    label: 'checkout.receipt_points'.tr(
                      namedArgs: {'points': '${extras.pointsUsed}'},
                    ),
                    kd: extras.pointsKd,
                  ),
                  const CheckoutReceiptTotalRow(),
                ],
              ),
            ),
          ),
          const CheckoutMinOrderNotice(),
        ],
      ),
    );
  }
}
