import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/offer_entity.dart';

/// One automatic cart promotion: what you get (icon + headline built from the
/// backend's reward), the backend's own name / description, and the condition
/// ("on orders over KD 5.000").
class OfferTile extends StatelessWidget {
  const OfferTile({super.key, required this.offer});

  final OfferEntity offer;

  @override
  Widget build(BuildContext context) {
    final (icon, reward) = switch (offer.rewardType) {
      OfferRewardType.freeDelivery => (
        Icons.local_shipping_outlined,
        'offers.reward_free_delivery'.tr(),
      ),
      OfferRewardType.percentageDiscount => (
        Icons.percent_rounded,
        'offers.reward_percent'.tr(namedArgs: {'percent': '${offer.percent}'}),
      ),
      OfferRewardType.fixedDiscount => (
        Icons.sell_outlined,
        'offers.reward_fixed'.tr(
          namedArgs: {'amount': Formatters.price(offer.amountKd)},
        ),
      ),
      OfferRewardType.freeProduct => (
        Icons.card_giftcard_rounded,
        'offers.reward_free_product'.tr(
          namedArgs: {'count': '${offer.freeQuantity}'},
        ),
      ),
      OfferRewardType.other => (Icons.local_offer_outlined, offer.name),
    };
    final condition = switch (offer.triggerType) {
      OfferTriggerType.cartSubtotal => 'offers.when_subtotal'.tr(
        namedArgs: {'amount': Formatters.price(offer.minSubtotalKd)},
      ),
      OfferTriggerType.itemQuantity || OfferTriggerType.categoryQuantity =>
        'offers.when_quantity'.tr(namedArgs: {'count': '${offer.minQuantity}'}),
      OfferTriggerType.other => '',
    };
    final cap = offer.maxDiscountKd;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        0,
        AppSpacing.s12,
        AppSpacing.s8,
      ),
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSize.s44,
            height: AppSize.s44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.finalPriceBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSize.s22, color: AppColors.finalPrice),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                if (condition.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    condition,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ],
                if (offer.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    offer.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
                if (cap != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'offers.max_discount'.tr(
                      namedArgs: {'amount': Formatters.price(cap)},
                    ),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.tertiaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
