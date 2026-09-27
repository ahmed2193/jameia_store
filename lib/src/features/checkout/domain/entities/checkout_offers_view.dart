import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import 'checkout_offer_card.dart';
import 'checkout_offer_hints.dart';

/// The offers half of the "Coupons & offers" page: what the cart already
/// applied, and what the basket is working towards, most progressed first.
class CheckoutOffersView extends Equatable {
  const CheckoutOffersView({
    this.applied = const <CheckoutOfferCard>[],
    this.locked = const <CheckoutOfferCard>[],
  });

  static const CheckoutOffersView empty = CheckoutOffersView();

  /// [offers] (`GET /v1/offers`, may be empty) enrich the cart's rows with
  /// their terms. A locked row is dropped when it is reached, already
  /// applied, a free-delivery goal the order cannot use (picked up, or
  /// delivery already free — [CheckoutOfferHints.wantsFreeDelivery], the
  /// checkout's own rule), or — when the list knows its offer — ended at
  /// [now] or limited to other branches than [branchId]. Without the list,
  /// the cart's rows alone build the cards.
  factory CheckoutOffersView.of({
    required List<OfferEntity> offers,
    required CartEntity cart,
    required DateTime now,
    required String? branchId,
  }) {
    final byId = <String, OfferEntity>{
      for (final offer in offers) offer.id: offer,
    };
    final wantsFreeDelivery = CheckoutOfferHints.wantsFreeDelivery(
      cart,
      pickup: cart.isPickup,
    );
    final appliedIds = <String>{
      for (final offer in cart.appliedOffers) offer.offerId,
    };
    final applied = <CheckoutOfferCard>[
      for (final row in cart.appliedOffers)
        CheckoutOfferCard(
          offerId: row.offerId,
          name: row.name,
          rewardType: row.reward.type,
          percent: row.reward.percent,
          amountFils: row.reward.amountFils,
          maxDiscountFils: row.reward.maxDiscountFils,
          minSubtotalFils: byId[row.offerId]?.minSubtotalFils ?? 0,
          minQuantity: byId[row.offerId]?.minQuantity ?? 0,
          stackable: byId[row.offerId]?.stackable,
          endsAt: byId[row.offerId]?.endsAt,
          savedFils: row.discountFils,
          fraction: 1,
        ),
    ];
    final locked = <(int, CheckoutOfferCard)>[];
    for (final row in cart.offerProgress) {
      if (row.isReached || appliedIds.contains(row.offerId)) continue;
      if (row.reward.type == OfferRewardType.freeDelivery &&
          !wantsFreeDelivery) {
        continue;
      }
      final offer = byId[row.offerId];
      if (offer != null &&
          (!offer.isLiveAt(now) || !offer.availableAt(branchId))) {
        continue;
      }
      locked.add((
        locked.length,
        CheckoutOfferCard(
          offerId: row.offerId,
          name: row.name,
          kind: row.kind,
          rewardType: row.reward.type,
          percent: row.reward.percent,
          amountFils: row.reward.amountFils,
          maxDiscountFils: row.reward.maxDiscountFils,
          minSubtotalFils: offer?.minSubtotalFils ?? 0,
          minQuantity: offer?.minQuantity ?? 0,
          contextId: row.contextId,
          contextName: row.contextName,
          rewardProductName: row.rewardProduct?.name,
          stackable: offer?.stackable,
          endsAt: offer?.endsAt,
          remainingValue: row.remainingValue,
          remainingIsFils: row.isSubtotal,
          fraction: row.fraction,
        ),
      ));
    }
    // Most progressed first; ties keep the server's order.
    locked.sort((a, b) {
      final byFraction = b.$2.fraction.compareTo(a.$2.fraction);
      return byFraction != 0 ? byFraction : a.$1.compareTo(b.$1);
    });
    return CheckoutOffersView(
      applied: List<CheckoutOfferCard>.unmodifiable(applied),
      locked: List<CheckoutOfferCard>.unmodifiable([
        for (final entry in locked) entry.$2,
      ]),
    );
  }

  final List<CheckoutOfferCard> applied;
  final List<CheckoutOfferCard> locked;

  bool get isEmpty => applied.isEmpty && locked.isEmpty;

  @override
  List<Object?> get props => [applied, locked];
}
