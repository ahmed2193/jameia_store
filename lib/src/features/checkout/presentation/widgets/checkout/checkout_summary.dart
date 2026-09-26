import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_totals_entity.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/jameia_money_text.dart';
import '../../../../../core/widgets/jameia_summary_line.dart';
import '../../../../../core/widgets/jameia_surface_card.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_section.dart';

/// The server cart's totals: what the order will cost. The values are static
/// (the bar's total is the one that rolls); the card only eases to its new
/// height when a row appears or goes.
class CheckoutSummary extends StatelessWidget {
  const CheckoutSummary({super.key});

  /// Stands in for a price the server has not quoted yet — here and in the
  /// place-order bar. No letters, so it reads the same in both locales.
  static const String unquoted = '—';

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
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        JameiaSummaryLine(
          label: 'checkout.summary_subtotal'.tr(),
          value: JameiaMoneyText(kd: totals.subtotalKd),
        ),
        if (totals.hasDiscount)
          JameiaSummaryLine(
            label: 'checkout.summary_discount'.tr(),
            value: JameiaMoneyText(
              kd: totals.discountKd,
              negative: true,
              color: AppColors.brandDeep,
            ),
          ),
        JameiaSummaryLine(
          label: 'checkout.summary_delivery'.tr(),
          // The server's deliveryFee already carries the express
          // surcharge; the two rows together are what it charges.
          value: !quoted
              ? const Text(unquoted)
              : totals.freeDelivery
              ? Text(
                  'checkout.summary_free'.tr(),
                  style: const TextStyle(color: AppColors.brandDeep),
                )
              : JameiaMoneyText(kd: totals.deliveryFeeWithoutExpressKd),
        ),
        if (quoted && totals.expressSurchargeFils > 0)
          JameiaSummaryLine(
            label: 'checkout.summary_express'.tr(),
            value: JameiaMoneyText(kd: totals.expressSurchargeKd),
          ),
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
          child: ThinDivider(),
        ),
        JameiaSummaryLine(
          label: 'checkout.summary_total'.tr(),
          emphasized: true,
          value: quoted
              ? JameiaMoneyText(kd: totals.totalKd)
              : const Text(unquoted),
        ),
      ],
    );
    return CheckoutSection(
      title: 'checkout.summary_title'.tr(),
      child: JameiaSurfaceCard(
        // Reduced motion → no AnimatedSize at all: at a zero duration it
        // restarts its controller inside layout and trips an assertion.
        // The card already clips to its corners; no second clip here.
        child: MotionGuard.reduced(context)
            ? rows
            : AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.signature,
                alignment: AlignmentDirectional.topStart,
                clipBehavior: Clip.none,
                child: rows,
              ),
      ),
    );
  }
}
