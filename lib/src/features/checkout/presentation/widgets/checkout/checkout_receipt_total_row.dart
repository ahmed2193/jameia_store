import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_savings.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/jameia_money_text.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_receipt.dart';
import 'checkout_receipt_row.dart';

/// What the total shows.
enum _TotalPhase {
  /// The destination is not priced yet: "—".
  unquoted,

  /// Taps are still on their way to the server: "Updating…".
  updating,

  /// The server's total, with "KD x off applied" under it.
  amount,
}

/// "Total", 16 sp bold. The value is static (the bar's total is the one
/// that rolls) and fades through "—" → "Updating…" → the amount. The
/// "KD x off applied" line (every saving: item promotions, discounts and a
/// waived delivery fee) lives inside the amount, so it is hidden with it
/// while the cart re-prices — it mixes local and server figures.
class CheckoutReceiptTotalRow extends StatelessWidget {
  const CheckoutReceiptTotalRow({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context
        .select<CheckoutCubit, ({bool quoted, int? quotedFee})>(
          (cubit) => (
            quoted: cubit.state.hasSelection,
            quotedFee: cubit.state.selection?.deliveryFeeFils,
          ),
        );
    final total = context
        .select<
          CartCubit,
          ({bool updating, double totalKd, bool saves, double savingsKd})
        >((cubit) {
          final state = cubit.state;
          final savings = CartSavings.of(
            state.cart,
            quotedDeliveryFeeFils: checkout.quotedFee,
          );
          return (
            updating: state.isUpdating,
            totalKd: state.cart.totals.totalKd,
            saves: savings.hasSavings,
            savingsKd: savings.totalSavingsKd,
          );
        });
    final phase = !checkout.quoted
        ? _TotalPhase.unquoted
        : total.updating
        ? _TotalPhase.updating
        : _TotalPhase.amount;
    return CheckoutReceiptRow(
      label: 'checkout.summary_total'.tr(),
      emphasized: true,
      value: FadeThroughSwitcher(
        stateKey: phase,
        alignment: AlignmentDirectional.topEnd,
        child: switch (phase) {
          _TotalPhase.unquoted => const Text(CheckoutReceipt.unquoted),
          _TotalPhase.updating => Text(
            'checkout.updating'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          _TotalPhase.amount => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              JameiaMoneyText(kd: total.totalKd),
              if (total.saves)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.s4),
                  child: Text(
                    'checkout.receipt_off_applied'.tr(
                      namedArgs: {'amount': Formatters.price(total.savingsKd)},
                    ),
                    textAlign: TextAlign.end,
                    // 12 sp regular: the deep red passes AA on the fill.
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.errorDeep,
                    ),
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}
