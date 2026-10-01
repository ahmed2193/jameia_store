import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/cart_totals_entity.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../../core/widgets/hero_summary_line.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_discount_line.dart';
import 'cart_free_delivery_value.dart';
import 'cart_pro_nudge.dart';

/// Subtotal, discounts, delivery fee and total as the server computed them.
/// While taps are still on their way, the discounts and total may lag: the
/// summary says so instead of guessing (a fade-through, no rolling — the bar
/// below rolls the same total). Hero Pro shows on the delivery row: a
/// member's free delivery carries the "pro" tag, and a customer without Pro
/// who pays a fee is told Pro would waive it.
class CartTotalsSummary extends StatelessWidget {
  const CartTotalsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final totals = context.select<CartCubit, CartTotalsEntity>(
      (cubit) => cubit.state.cart.totals,
    );
    final updating = context.select<CartCubit, bool>(
      (cubit) => cubit.state.isUpdating,
    );
    final eta = totals.etaMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeroSummaryLine(
          label: 'cart.summary_subtotal'.tr(),
          value: HeroMoneyText(kd: totals.subtotalKd),
        ),
        if (totals.offerDiscountFils > 0)
          CartDiscountLine(
            label: 'cart.summary_offers'.tr(),
            kd: totals.offerDiscountKd,
          ),
        if (totals.couponDiscountFils > 0)
          CartDiscountLine(
            label: 'cart.summary_coupon'.tr(),
            kd: totals.couponDiscountKd,
          ),
        if (totals.loyaltyDiscountFils > 0)
          CartDiscountLine(
            label: 'cart.summary_loyalty'.tr(),
            kd: totals.loyaltyDiscountKd,
          ),
        HeroSummaryLine(
          label: 'cart.summary_delivery'.tr(),
          // Without the express part, which gets its own row below: the
          // server folds it into deliveryFee, so showing both would add
          // up past the total.
          value: totals.freeDelivery
              ? const CartFreeDeliveryValue()
              : HeroMoneyText(kd: totals.deliveryFeeWithoutExpressKd),
        ),
        // Hero Pro would waive that fee: a customer without Pro is told
        // how much (never a member).
        const CartProNudge(),
        if (totals.expressSurchargeFils > 0)
          HeroSummaryLine(
            label: 'cart.summary_express'.tr(),
            value: HeroMoneyText(kd: totals.expressSurchargeKd),
          ),
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
          child: ThinDivider(),
        ),
        HeroSummaryLine(
          label: 'cart.summary_total'.tr(),
          emphasized: true,
          value: FadeThroughSwitcher(
            stateKey: updating,
            alignment: AlignmentDirectional.centerEnd,
            child: updating
                ? Text(
                    'cart.updating'.tr(),
                    style: const TextStyle(color: AppColors.secondaryText),
                  )
                : HeroMoneyText(kd: totals.totalKd),
          ),
        ),
        if (eta != null && eta > 0)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
            child: Row(
              children: [
                const HeroIcon(
                  HeroIcons.clock,
                  size: AppSize.s16,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: AppSpacing.s6),
                Expanded(
                  child: Text(
                    'cart.summary_eta'.tr(namedArgs: {'minutes': '$eta'}),
                    style: AppTextStyles.meta,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
