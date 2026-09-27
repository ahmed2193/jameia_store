import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_applied_offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_offer_hints.dart';

/// The live offers: free delivery over 5 KWD (all branches), 10% over 15 KWD
/// capped at 3 KWD (Salmiya b1 + Hawalli b2), 2 KWD off 3 dairy items, and a
/// scheduled 1 KWD over 20 KWD that does not combine.
const List<OfferEntity> _offers = <OfferEntity>[
  OfferEntity(
    id: 'free',
    name: 'Free delivery over 5 KWD',
    triggerType: OfferTriggerType.cartSubtotal,
    minSubtotalFils: 5000,
    rewardType: OfferRewardType.freeDelivery,
    stackable: true,
  ),
  OfferEntity(
    id: 'pct',
    name: '10% off over 15 KWD',
    triggerType: OfferTriggerType.cartSubtotal,
    minSubtotalFils: 15000,
    rewardType: OfferRewardType.percentageDiscount,
    percent: 10,
    maxDiscountFils: 3000,
    stackable: true,
    branchIds: <String>['b1', 'b2'],
  ),
  OfferEntity(
    id: 'dairy',
    name: '2 KWD off dairy',
    triggerType: OfferTriggerType.categoryQuantity,
    minQuantity: 3,
    rewardType: OfferRewardType.fixedDiscount,
    amountFils: 2000,
    stackable: true,
  ),
  OfferEntity(
    id: 'summer',
    name: 'Scheduled summer offer',
    triggerType: OfferTriggerType.cartSubtotal,
    minSubtotalFils: 20000,
    rewardType: OfferRewardType.fixedDiscount,
    amountFils: 1000,
  ),
];

CartOfferProgressEntity _progress(
  String id,
  int remaining, {
  OfferProgressKind kind = OfferProgressKind.subtotal,
  OfferRewardType reward = OfferRewardType.fixedDiscount,
}) => CartOfferProgressEntity(
  offerId: id,
  name: id,
  kind: kind,
  currentValue: 2100,
  targetValue: 2100 + remaining,
  remainingValue: remaining,
  reward: OfferRewardEntity(type: reward),
);

final List<CartOfferProgressEntity> _progressRows = <CartOfferProgressEntity>[
  _progress('free', 2900, reward: OfferRewardType.freeDelivery),
  _progress('pct', 12900, reward: OfferRewardType.percentageDiscount),
  _progress('dairy', 2, kind: OfferProgressKind.category),
  _progress('summer', 17900),
  // Not in the offer list: its terms are unknown, so it is never advertised.
  _progress('mystery', 100),
];

CartEntity _cart({
  bool free = false,
  List<CartAppliedOfferEntity> applied = const <CartAppliedOfferEntity>[],
}) => CartEntity(
  offerProgress: _progressRows,
  appliedOffers: applied,
  totals: CartTotalsEntity(subtotalFils: 2100, freeDelivery: free),
);

CheckoutOfferHints _hints({
  CartEntity? cart,
  String? branchId = 'b1',
  bool pickup = false,
  bool proFreeDelivery = false,
}) => CheckoutOfferHints.of(
  cart: cart ?? _cart(),
  offers: _offers,
  branchId: branchId,
  pickup: pickup,
  proFreeDelivery: proFreeDelivery,
);

void main() {
  test('the nearest eligible reward, with its terms from the offer', () {
    final hints = _hints();

    expect(hints.nearestUnlock?.offerId, 'free');
    expect(hints.nearestUnlock?.remainingFils, 2900);
    expect(hints.nearestUnlock?.remainingKd, 2.9);
    expect(hints.nearestUnlock?.rewardType, OfferRewardType.freeDelivery);
    expect(hints.freeDeliveryGapFils, 2900);
    expect(hints.freeDeliveryGapKd, 2.9);
  });

  test('free delivery is skipped once delivery is free, and for pickup', () {
    final free = _hints(cart: _cart(free: true));
    expect(free.nearestUnlock?.offerId, 'pct');
    expect(free.nearestUnlock?.percent, 10);
    expect(free.nearestUnlock?.maxDiscountFils, 3000);
    expect(free.nearestUnlock?.maxDiscountKd, 3.0);
    expect(free.freeDeliveryGapFils, isNull);
    expect(free.freeDeliveryGapKd, isNull);

    final pickup = _hints(pickup: true);
    expect(pickup.nearestUnlock?.offerId, 'pct');
    expect(pickup.freeDeliveryGapFils, isNull);
  });

  test('skips un-enriched, non-stackable, branch-limited and count offers', () {
    // At another branch the 10% offer is out; "summer" never combines,
    // "mystery" is unknown and "dairy" counts pieces, not the subtotal.
    final elsewhere = _hints(cart: _cart(free: true), branchId: 'b9');
    expect(elsewhere.nearestUnlock, isNull);

    // No branch known yet: a branch-limited offer is not advertised.
    expect(
      _hints(cart: _cart(free: true), branchId: null).nearestUnlock,
      isNull,
    );
  });

  test('without the offer list nothing is advertised', () {
    final hints = CheckoutOfferHints.of(
      cart: _cart(),
      offers: const <OfferEntity>[],
      branchId: 'b1',
      pickup: false,
      proFreeDelivery: false,
    );

    expect(hints, CheckoutOfferHints.none);
  });

  group('why delivery is free', () {
    test('an applied free-delivery offer, with its name', () {
      final hints = _hints(
        cart: _cart(
          free: true,
          applied: const <CartAppliedOfferEntity>[
            CartAppliedOfferEntity(
              offerId: 'free',
              name: 'Free delivery over 5 KWD',
              reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
            ),
          ],
        ),
        proFreeDelivery: true,
      );

      expect(hints.freeDeliveryReason, FreeDeliveryReason.offer);
      expect(hints.appliedFreeDeliveryName, 'Free delivery over 5 KWD');
    });

    test('Pro, when the perk runs and the customer is a member', () {
      expect(
        _hints(
          cart: _cart(free: true),
          proFreeDelivery: true,
        ).freeDeliveryReason,
        FreeDeliveryReason.pro,
      );
      expect(
        _hints(cart: _cart(free: true)).freeDeliveryReason,
        FreeDeliveryReason.none,
      );
      // Not free: no reason, Pro or not.
      expect(
        _hints(proFreeDelivery: true).freeDeliveryReason,
        FreeDeliveryReason.none,
      );
    });
  });
}
