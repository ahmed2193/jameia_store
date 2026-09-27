import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/cart_savings.dart';
import '../../../../../core/domain/entities/offer_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/jameia_money_text.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_offer_hints.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_offers_cubit.dart';
import 'checkout_receipt.dart';
import 'checkout_receipt_row.dart';

/// The receipt's delivery line.
///
/// Delivery: "—" until the server priced the destination; "Free" (with the
/// waived fee struck at the end) when delivery is free and nothing is still
/// charged (`CartTotalsEntity.deliveryIsFree`, the bar's rule too);
/// otherwise the fee without the express surcharge (express has
/// its own line). The grey sub-line says why it is free — the applied offer
/// by name, or Jm3eia Pro — or what is missing for free delivery.
///
/// Pickup: "Pickup", "—" until a branch is chosen, then "No fee" at zero or
/// the server's fee.
class CheckoutReceiptDeliveryRow extends StatelessWidget {
  const CheckoutReceiptDeliveryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context
        .select<
          CheckoutCubit,
          ({
            bool pickup,
            bool quoted,
            String? branchId,
            int? quotedFee,
            bool proPerk,
          })
        >((cubit) {
          final state = cubit.state;
          return (
            pickup: state.draft.isPickup,
            quoted: state.hasSelection,
            branchId: state.selection?.branchId,
            quotedFee: state.selection?.deliveryFeeFils,
            proPerk: state.rules.proFreeDelivery,
          );
        });
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    final offers = context.select<CheckoutOffersCubit, List<OfferEntity>>(
      (cubit) => cubit.state.offers,
    );
    final delivery = context
        .select<
          CartCubit,
          ({
            bool free,
            int feeFils,
            double feeKd,
            bool waived,
            double waivedKd,
            double? gapKd,
            FreeDeliveryReason reason,
            String offerName,
          })
        >((cubit) {
          final cart = cubit.state.cart;
          final totals = cart.totals;
          final savings = CartSavings.of(
            cart,
            quotedDeliveryFeeFils: checkout.quotedFee,
          );
          final hints = CheckoutOfferHints.of(
            cart: cart,
            offers: offers,
            branchId: checkout.branchId,
            pickup: checkout.pickup,
            proFreeDelivery: checkout.proPerk && isPro,
          );
          // Only what this line reads, so an unlock's amount moving with the
          // subtotal does not rebuild it.
          return (
            free: totals.deliveryIsFree,
            feeFils: totals.deliveryFeeWithoutExpressFils,
            feeKd: totals.deliveryFeeWithoutExpressKd,
            waived: savings.waivedDeliveryFils > 0,
            waivedKd: savings.waivedDeliveryKd,
            gapKd: hints.freeDeliveryGapKd,
            reason: hints.freeDeliveryReason,
            offerName: hints.appliedFreeDeliveryName,
          );
        });

    if (checkout.pickup) {
      return CheckoutReceiptRow(
        label: 'checkout.receipt_pickup'.tr(),
        value: !checkout.quoted
            ? const Text(CheckoutReceipt.unquoted)
            : delivery.feeFils == 0
            ? Text('checkout.receipt_no_fee'.tr())
            : JameiaMoneyText(kd: delivery.feeKd),
      );
    }

    final gapKd = delivery.gapKd;
    final note = !checkout.quoted
        ? null
        : switch (delivery.reason) {
            FreeDeliveryReason.offer => 'checkout.receipt_offer_applied'.tr(
              namedArgs: {'name': delivery.offerName},
            ),
            FreeDeliveryReason.pro => 'checkout.receipt_pro_free_delivery'.tr(),
            FreeDeliveryReason.none =>
              delivery.free || gapKd == null
                  ? null
                  : 'checkout.receipt_free_delivery_gap'.tr(
                      namedArgs: {'amount': Formatters.price(gapKd)},
                    ),
          };
    return CheckoutReceiptRow(
      label: 'checkout.summary_delivery'.tr(),
      value: !checkout.quoted
          ? const Text(CheckoutReceipt.unquoted)
          : delivery.free
          ? Text(
              'checkout.summary_free'.tr(),
              style: const TextStyle(color: AppColors.freeDelivery),
            )
          : JameiaMoneyText(kd: delivery.feeKd),
      note: note,
      struck: checkout.quoted && delivery.free && delivery.waived
          ? JameiaMoneyText(
              kd: delivery.waivedKd,
              strike: true,
              color: AppColors.tertiaryText,
            )
          : null,
    );
  }
}
