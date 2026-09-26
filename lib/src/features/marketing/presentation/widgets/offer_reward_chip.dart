import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/utils/formatters.dart';

/// What the offer gives, in a marker-lime chip: "Save 10%", "Save KD 1.000",
/// "Free delivery", "1 free item". Nothing for a reward the app does not
/// know.
class OfferRewardChip extends StatelessWidget {
  const OfferRewardChip({super.key, required this.offer});

  final OfferEntity offer;

  @override
  Widget build(BuildContext context) {
    final label = switch (offer.rewardType) {
      OfferRewardType.percentageDiscount => 'offers.chip_save_percent'.tr(
        namedArgs: {'percent': '${offer.percent}'},
      ),
      OfferRewardType.fixedDiscount => 'offers.chip_save_amount'.tr(
        namedArgs: {'amount': Formatters.price(offer.amountKd)},
      ),
      OfferRewardType.freeDelivery => 'offers.reward_free_delivery'.tr(),
      OfferRewardType.freeProduct => 'offers.reward_free_product'.tr(
        namedArgs: {'count': '${offer.freeQuantity}'},
      ),
      OfferRewardType.other => null,
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: AppColors.proLime,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primaryText,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
