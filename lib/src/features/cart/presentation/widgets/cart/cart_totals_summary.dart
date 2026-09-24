import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_totals_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/summary_row.dart';
import '../../cubit/cart_cubit.dart';

/// Subtotal, discounts, delivery fee and total as the server computed them.
/// While taps are still on their way, the discounts and total may lag: the
/// summary says so instead of guessing.
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
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SummaryRow(
            label: 'cart.summary_subtotal'.tr(),
            value: Formatters.price(totals.subtotalKd),
          ),
          if (totals.offerDiscountFils > 0)
            SummaryRow(
              label: 'cart.summary_offers'.tr(),
              value: '- ${Formatters.price(totals.offerDiscountKd)}',
              valueColor: AppColors.success,
            ),
          if (totals.couponDiscountFils > 0)
            SummaryRow(
              label: 'cart.summary_coupon'.tr(),
              value: '- ${Formatters.price(totals.couponDiscountKd)}',
              valueColor: AppColors.success,
            ),
          if (totals.loyaltyDiscountFils > 0)
            SummaryRow(
              label: 'cart.summary_loyalty'.tr(),
              value: '- ${Formatters.price(totals.loyaltyDiscountKd)}',
              valueColor: AppColors.success,
            ),
          SummaryRow(
            label: 'cart.summary_delivery'.tr(),
            // Without the express part, which gets its own row below: the
            // server folds it into deliveryFee, so showing both would add
            // up past the total.
            value: totals.freeDelivery
                ? 'cart.summary_free'.tr()
                : Formatters.price(totals.deliveryFeeWithoutExpressKd),
            valueColor: totals.freeDelivery ? AppColors.freeDelivery : null,
          ),
          if (totals.expressSurchargeFils > 0)
            SummaryRow(
              label: 'cart.summary_express'.tr(),
              value: Formatters.price(totals.expressSurchargeKd),
            ),
          const SizedBox(height: AppSpacing.s4),
          SummaryRow(
            label: 'cart.summary_total'.tr(),
            value: updating
                ? 'cart.updating'.tr()
                : Formatters.price(totals.totalKd),
            emphasized: true,
            valueColor: updating ? AppColors.tertiaryText : null,
          ),
          if (eta != null && eta > 0)
            Text(
              'cart.summary_eta'.tr(namedArgs: {'minutes': '$eta'}),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}
