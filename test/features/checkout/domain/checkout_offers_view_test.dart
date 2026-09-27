import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_applied_offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_offers_view.dart';

final DateTime _now = DateTime(2026, 9, 26, 12);

CartOfferProgressEntity _progress(
  String id, {
  required int current,
  required int target,
  OfferProgressKind kind = OfferProgressKind.subtotal,
  String? contextName,
}) => CartOfferProgressEntity(
  offerId: id,
  name: 'Offer $id',
  kind: kind,
  currentValue: current,
  targetValue: target,
  remainingValue: target - current,
  contextName: contextName,
  reward: const OfferRewardEntity(
    type: OfferRewardType.fixedDiscount,
    amountFils: 1000,
  ),
);

const CartAppliedOfferEntity _applied = CartAppliedOfferEntity(
  offerId: 'free',
  name: 'Free delivery over 5 KWD',
  discountFils: 650,
  reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
);

void main() {
  final cart = CartEntity(
    appliedOffers: const <CartAppliedOfferEntity>[_applied],
    offerProgress: <CartOfferProgressEntity>[
      // Already applied: never locked as well.
      _progress('free', current: 6000, target: 5000),
      _progress('near', current: 4000, target: 5000),
      _progress('far', current: 1000, target: 20000),
      _progress(
        'dairy',
        current: 2,
        target: 3,
        kind: OfferProgressKind.category,
        contextName: 'Dairy & Eggs',
      ),
      _progress('ended', current: 4500, target: 5000),
      _progress('elsewhere', current: 4800, target: 5000),
      _progress('solo', current: 2000, target: 5000),
      _progress('reached', current: 5000, target: 5000),
    ],
  );
  final offers = <OfferEntity>[
    const OfferEntity(
      id: 'free',
      name: 'Free delivery over 5 KWD',
      minSubtotalFils: 5000,
      rewardType: OfferRewardType.freeDelivery,
      stackable: true,
    ),
    const OfferEntity(id: 'near', name: 'Near', stackable: true),
    OfferEntity(
      id: 'ended',
      name: 'Ended',
      stackable: true,
      endsAt: DateTime(2026, 9, 25),
    ),
    const OfferEntity(
      id: 'elsewhere',
      name: 'Elsewhere',
      stackable: true,
      branchIds: <String>['b2'],
    ),
    const OfferEntity(id: 'solo', name: 'Solo'),
  ];

  CheckoutOffersView view({List<OfferEntity>? list, String? branchId = 'b1'}) =>
      CheckoutOffersView.of(
        offers: list ?? offers,
        cart: cart,
        now: _now,
        branchId: branchId,
      );

  test('applied comes from the cart, enriched by the offer list', () {
    final applied = view().applied.single;

    expect(applied.offerId, 'free');
    expect(applied.isApplied, isTrue);
    expect(applied.savedFils, 650);
    expect(applied.savedKd, 0.65);
    expect(applied.minSubtotalFils, 5000);
    expect(applied.stackable, isTrue);
    expect(applied.rewardType, OfferRewardType.freeDelivery);
  });

  test('locked: most progressed first; drops reached, applied, ended and '
      'other-branch offers', () {
    final locked = view().locked;

    expect(locked.map((card) => card.offerId), <String>[
      'near', // 0.8
      'dairy', // 0.67
      'solo', // 0.4
      'far', // 0.05 (unknown to the list: kept from the cart alone)
    ]);
    expect(locked.every((card) => !card.isApplied), isTrue);
  });

  test('a count offer says pieces, a subtotal offer says fils', () {
    final locked = view().locked;
    final dairy = locked.firstWhere((card) => card.offerId == 'dairy');
    final near = locked.firstWhere((card) => card.offerId == 'near');

    expect(dairy.remainingIsFils, isFalse);
    expect(dairy.remainingValue, 1);
    expect(dairy.contextName, 'Dairy & Eggs');
    expect(near.remainingIsFils, isTrue);
    expect(near.remainingKd, 1.0);
  });

  test(
    'a non-stackable offer only qualifies; an unknown one is not flagged',
    () {
      final locked = view().locked;

      expect(
        locked.firstWhere((card) => card.offerId == 'solo').qualifiesOnly,
        isTrue,
      );
      expect(
        locked.firstWhere((card) => card.offerId == 'near').qualifiesOnly,
        isFalse,
      );
      final far = locked.firstWhere((card) => card.offerId == 'far');
      expect(far.stackable, isNull);
      expect(far.qualifiesOnly, isFalse);
    },
  );

  test('without the offer list the cart alone builds the cards', () {
    final bare = view(list: const <OfferEntity>[]);

    expect(bare.applied.single.offerId, 'free');
    expect(bare.applied.single.stackable, isNull);
    // Nothing to drop them by: ended / other-branch rows stay.
    expect(
      bare.locked.map((card) => card.offerId),
      containsAll(<String>['ended', 'elsewhere']),
    );
  });

  test('the branch that offers "elsewhere" keeps it', () {
    expect(
      view(branchId: 'b2').locked.map((card) => card.offerId),
      contains('elsewhere'),
    );
  });

  group('a free-delivery goal the order cannot use is not a goal', () {
    const goal = CartOfferProgressEntity(
      offerId: 'ship',
      name: 'Free delivery over 5 KWD',
      kind: OfferProgressKind.subtotal,
      currentValue: 3000,
      targetValue: 5000,
      remainingValue: 2000,
      reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
    );

    List<String> lockedOf(CartEntity basket) => CheckoutOffersView.of(
      offers: const <OfferEntity>[],
      cart: basket,
      now: _now,
      branchId: 'b1',
    ).locked.map((card) => card.offerId).toList();

    test('delivered and paying for delivery: still a goal', () {
      expect(
        lockedOf(
          const CartEntity(
            offerProgress: <CartOfferProgressEntity>[goal],
            totals: CartTotalsEntity(deliveryFeeFils: 650),
          ),
        ),
        <String>['ship'],
      );
    });

    test('picked up: dropped', () {
      expect(
        lockedOf(
          const CartEntity(
            offerProgress: <CartOfferProgressEntity>[goal],
            fulfillmentMode: FulfillmentMode.pickup,
          ),
        ),
        isEmpty,
      );
    });

    test('delivery already free (Pro): dropped', () {
      expect(
        lockedOf(
          const CartEntity(
            offerProgress: <CartOfferProgressEntity>[goal],
            totals: CartTotalsEntity(freeDelivery: true),
          ),
        ),
        isEmpty,
      );
    });
  });
}
