import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_savings.dart';
import '../../../../../core/widgets/hero_bar_total.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_receipt.dart';

/// The bar's total in 20 bold — the page's one rolling number — with the
/// struck total beside it (what the basket costs without any of its
/// savings, [CartSavings.struckTotalFils]).
///
/// Never a stale amount: "—" until a destination is priced, "Updating…"
/// while cart taps are still on their way (the amount stays mounted under
/// the placeholder, so the new total rolls from the old one). The struck
/// total mixes local and server figures, so it only shows next to a settled
/// total. The whole line scales down rather than overflow (KD has three
/// decimals).
class CheckoutBarTotal extends StatelessWidget {
  const CheckoutBarTotal({super.key});

  @override
  Widget build(BuildContext context) {
    final (quoted, quotedFeeFils) = context.select<CheckoutCubit, (bool, int?)>(
      (cubit) =>
          (cubit.state.hasSelection, cubit.state.selection?.deliveryFeeFils),
    );
    final (totalKd, struckKd, updating) = context
        .select<CartCubit, (double, double?, bool)>((cubit) {
          final state = cubit.state;
          return (
            state.cart.totals.totalKd,
            CartSavings.of(
              state.cart,
              quotedDeliveryFeeFils: quotedFeeFils,
            ).struckTotalKd,
            state.isUpdating,
          );
        });
    final settled = quoted && !updating;
    final struck = settled ? struckKd : null;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroBarTotal(
            kd: settled ? totalKd : null,
            placeholder: quoted
                ? 'checkout.updating'.tr()
                : CheckoutReceipt.unquoted,
            alignment: AlignmentDirectional.centerStart,
            style: AppTextStyles.sectionTitle,
            placeholderStyle: quoted
                ? AppTextStyles.meta
                : AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.secondaryText,
                  ),
          ),
          if (struck != null) ...[
            const SizedBox(width: AppSpacing.s6),
            HeroMoneyText(
              kd: struck,
              strike: true,
              color: AppColors.tertiaryText,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}
