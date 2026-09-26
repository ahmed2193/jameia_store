import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/utils/formatters.dart';
import 'offer_term_row.dart';

/// The small print of an offer, under a hairline: what the cart must hold,
/// the cap of a percentage off, and the last day ([showsEndDate]; an offer
/// counting down shows its clock instead). Nothing when the offer has none.
class OfferTerms extends StatelessWidget {
  const OfferTerms({super.key, required this.offer, this.showsEndDate = true});

  final OfferEntity offer;
  final bool showsEndDate;

  @override
  Widget build(BuildContext context) {
    final condition = switch (offer.triggerType) {
      OfferTriggerType.cartSubtotal => 'offers.when_subtotal'.tr(
        namedArgs: {'amount': Formatters.price(offer.minSubtotalKd)},
      ),
      OfferTriggerType.itemQuantity || OfferTriggerType.categoryQuantity =>
        'offers.when_quantity'.tr(namedArgs: {'count': '${offer.minQuantity}'}),
      OfferTriggerType.other => '',
    };
    final cap = offer.maxDiscountKd;
    final endsAt = showsEndDate ? offer.endsAt : null;
    if (condition.isEmpty && cap == null && endsAt == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s6,
        children: [
          if (condition.isNotEmpty)
            OfferTermRow(
              icon: Icons.shopping_basket_outlined,
              text: condition,
              emphasized: true,
            ),
          if (cap != null)
            OfferTermRow(
              icon: Icons.savings_outlined,
              text: 'offers.max_discount'.tr(
                namedArgs: {'amount': Formatters.price(cap)},
              ),
            ),
          if (endsAt != null)
            OfferTermRow(
              icon: Icons.event_outlined,
              text: 'offers.valid_until'.tr(
                namedArgs: {
                  'date': Formatters.date(context.locale.languageCode, endsAt),
                },
              ),
            ),
        ],
      ),
    );
  }
}
