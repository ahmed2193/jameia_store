import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/utils/formatters.dart';

/// The offer's bold ink title: the backend's own name, or — for a nameless
/// offer — a headline built from its reward ("10% off your order").
class OfferTitle extends StatelessWidget {
  const OfferTitle({super.key, required this.offer});

  final OfferEntity offer;

  static const int _maxLines = 2;

  @override
  Widget build(BuildContext context) {
    final title = offer.name.isNotEmpty
        ? offer.name
        : switch (offer.rewardType) {
            OfferRewardType.freeDelivery => 'offers.reward_free_delivery'.tr(),
            OfferRewardType.percentageDiscount => 'offers.reward_percent'.tr(
              namedArgs: {'percent': '${offer.percent}'},
            ),
            OfferRewardType.fixedDiscount => 'offers.reward_fixed'.tr(
              namedArgs: {'amount': Formatters.price(offer.amountKd)},
            ),
            OfferRewardType.freeProduct => 'offers.reward_free_product'.tr(
              namedArgs: {'count': '${offer.freeQuantity}'},
            ),
            OfferRewardType.other => 'offers.title'.tr(),
          };
    return Text(
      title,
      maxLines: _maxLines,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.headingMedium.copyWith(
        color: AppColors.primaryText,
        fontWeight: AppTextStyles.bold,
      ),
    );
  }
}
