import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_totals_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/summary_row.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';

/// The server cart's totals: what the order will cost.
class CheckoutSummary extends StatelessWidget {
  const CheckoutSummary({super.key});

  /// Stands in for a price the server has not quoted yet. No letters, so it
  /// reads the same in both locales.
  static const String _unquoted = '—';

  @override
  Widget build(BuildContext context) {
    final totals = context.select<CartCubit, CartTotalsEntity>(
      (cubit) => cubit.state.cart.totals,
    );
    // Until a destination is chosen the cart still carries the OTHER mode's
    // delivery fee: switch to pickup and the total keeps a 0.500 charge, start
    // on pickup with no saved address and it quotes 0.000 and then climbs. The
    // server prices the order when the destination is selected, so show nothing
    // rather than a number that is about to move.
    final quoted = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.selection != null,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SummaryRow(
            label: 'checkout.summary_subtotal'.tr(),
            value: Formatters.price(totals.subtotalKd),
          ),
          if (totals.hasDiscount)
            SummaryRow(
              label: 'checkout.summary_discount'.tr(),
              value: '- ${Formatters.price(totals.discountKd)}',
              valueColor: AppColors.success,
            ),
          SummaryRow(
            label: 'checkout.summary_delivery'.tr(),
            // The server's deliveryFee already carries the express
            // surcharge; the two rows together are what it charges.
            value: !quoted
                ? _unquoted
                : totals.freeDelivery
                ? 'checkout.summary_free'.tr()
                : Formatters.price(totals.deliveryFeeWithoutExpressKd),
            valueColor: quoted && totals.freeDelivery
                ? AppColors.freeDelivery
                : null,
          ),
          if (quoted && totals.expressSurchargeFils > 0)
            SummaryRow(
              label: 'checkout.summary_express'.tr(),
              value: Formatters.price(totals.expressSurchargeKd),
            ),
          SummaryRow(
            label: 'checkout.summary_total'.tr(),
            value: quoted ? Formatters.price(totals.totalKd) : _unquoted,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}
