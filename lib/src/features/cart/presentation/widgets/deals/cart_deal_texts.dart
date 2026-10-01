import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/domain/entities/offer_reward_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/cart_offers_view.dart';

/// How the deals strip and sheet word an offer. The offer's own name comes
/// from the server; these are the app's phrases around it.
abstract final class CartDealTexts {
  /// The short, lower-case reward ("free delivery", "10% off",
  /// "KD 2.000 off"), as the strip's headline reads it.
  static String reward(OfferRewardEntity reward) => switch (reward.type) {
    OfferRewardType.freeDelivery => 'cart.reward_free_delivery'.tr(),
    OfferRewardType.percentageDiscount => 'cart.reward_percentage'.tr(
      namedArgs: {'percent': '${reward.percent}'},
    ),
    OfferRewardType.fixedDiscount => 'cart.reward_fixed'.tr(
      namedArgs: {'amount': Formatters.price(reward.amountKd)},
    ),
    OfferRewardType.freeProduct => 'cart.reward_free_product'.tr(),
    OfferRewardType.other => 'cart.reward_other'.tr(),
  };

  /// The strip's headline: the next deal to unlock, or the "best deal"
  /// cheer once every offer is earned.
  static String headline(CartOffersView view) {
    final next = view.next;
    if (next == null) return 'cart.best_deal'.tr();
    final prize = reward(next.reward);
    return next.isSubtotal
        ? 'cart.offer_progress_subtotal'.tr(
            namedArgs: {
              'amount': Formatters.price(next.remainingKd),
              'reward': prize,
            },
          )
        : 'cart.offer_progress_items'.tr(
            namedArgs: {'count': '${next.remainingValue}', 'reward': prize},
          );
  }

  /// A sheet card's second line: what was saved, or what is still missing.
  static String status(CartDealEntity deal) {
    if (deal.applied) {
      return deal.savedFils > 0
          ? 'cart.deal_applied_saved'.tr(
              namedArgs: {'amount': Formatters.price(deal.savedKd)},
            )
          : 'cart.deal_applied'.tr();
    }
    if (deal.isSubtotal) {
      return 'cart.deal_add_amount'.tr(
        namedArgs: {'amount': Formatters.price(deal.remainingKd)},
      );
    }
    final category = deal.contextName;
    return category == null || category.isEmpty
        ? 'cart.deal_add_items'.tr(
            namedArgs: {'count': '${deal.remainingValue}'},
          )
        : 'cart.deal_add_from'.tr(
            namedArgs: {
              'count': '${deal.remainingValue}',
              'category': category,
            },
          );
  }
}
