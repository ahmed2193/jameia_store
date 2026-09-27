import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/offer_reward_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/checkout_offer_card.dart';

/// A ticket's terms under its headline — "Min. order KD 5.000 · Save up to
/// KD 3.000" / "Buy 3 from Dairy" — and, for an applied offer, what it
/// saved. Only terms the store's offer list gives; nothing when none is
/// known.
class CheckoutOfferTerms extends StatelessWidget {
  const CheckoutOfferTerms({super.key, required this.card});

  final CheckoutOfferCard card;

  static String _terms(CheckoutOfferCard card) {
    final cap = card.maxDiscountKd;
    final context = card.contextName;
    return <String>[
      if (card.minSubtotalFils > 0)
        'checkout.offer_min_order'.tr(
          namedArgs: {'amount': Formatters.price(card.minSubtotalKd)},
        ),
      if (card.minQuantity > 0 && context != null)
        'checkout.offer_min_qty'.tr(
          namedArgs: {'count': '${card.minQuantity}', 'name': context},
        ),
      if (card.rewardType == OfferRewardType.percentageDiscount && cap != null)
        'checkout.offer_cap'.tr(namedArgs: {'amount': Formatters.price(cap)}),
    ].join(Formatters.middot);
  }

  @override
  Widget build(BuildContext context) {
    final terms = _terms(card);
    final saved = card.savedKd;
    final showSaved = saved != null && saved > 0;
    if (terms.isEmpty && !showSaved) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (terms.isNotEmpty)
            Text(
              terms,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          if (showSaved)
            Text(
              'checkout.coupon_saved'.tr(
                namedArgs: {'amount': Formatters.price(saved)},
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorDeep,
              ),
            ),
        ],
      ),
    );
  }
}
