import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/offer_reward_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/checkout_offer_card.dart';
import 'checkout_offer_expiry.dart';
import 'checkout_offer_status.dart';
import 'checkout_offer_terms.dart';
import 'checkout_ticket_card.dart';
import 'checkout_ticket_headline.dart';

/// One offer as a Keeta ticket: the reward ("10% off", "KD 1.000 off",
/// "Free delivery", "Free {product}"), its terms, the offer's own name and
/// when it ends, then "✓ Applied" (beside the name) or the progress still
/// to make (under it). The ribbon says whether it combines with other
/// offers, when the store's list knows. No "Apply" and no "Best offer":
/// offers apply by themselves and the API does not rank them.
class CheckoutOfferTicket extends StatelessWidget {
  const CheckoutOfferTicket({super.key, required this.card});

  final CheckoutOfferCard card;

  static String _headline(CheckoutOfferCard card) {
    final product = card.rewardProductName;
    return switch (card.rewardType) {
      OfferRewardType.percentageDiscount => 'checkout.offer_percent'.tr(
        namedArgs: {'percent': '${card.percent}'},
      ),
      OfferRewardType.fixedDiscount => 'checkout.offer_amount'.tr(
        namedArgs: {'amount': Formatters.price(card.amountKd)},
      ),
      OfferRewardType.freeDelivery => 'core.free_delivery'.tr(),
      OfferRewardType.freeProduct when product != null =>
        'checkout.offer_free_product'.tr(namedArgs: {'name': product}),
      OfferRewardType.freeProduct => 'checkout.offer_free_gift'.tr(),
      OfferRewardType.other => card.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ribbon = switch (card.stackable) {
      true => 'checkout.offer_stackable'.tr(),
      false => 'checkout.offer_not_stackable'.tr(),
      null => null,
    };
    // An "other" reward already shows the offer's name as its headline.
    final showName = card.rewardType != OfferRewardType.other;
    return CheckoutTicketCard(
      ribbon: ribbon,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutTicketHeadline(text: _headline(card)),
          CheckoutOfferTerms(card: card),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showName)
                      Text(
                        card.name,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: AppTextStyles.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    CheckoutOfferExpiry(endsAt: card.endsAt),
                  ],
                ),
              ),
              if (card.isApplied) ...[
                const SizedBox(width: AppSpacing.s12),
                CheckoutOfferStatus(card: card),
              ],
            ],
          ),
          if (!card.isApplied) ...[
            const SizedBox(height: AppSpacing.s12),
            CheckoutOfferStatus(card: card),
          ],
        ],
      ),
    );
  }
}
