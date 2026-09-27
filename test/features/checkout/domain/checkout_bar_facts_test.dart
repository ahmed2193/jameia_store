import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_loyalty_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_savings.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_bar_fact.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_bar_facts.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_block_reason.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_offer_hints.dart';

const CartLineEntity _line = CartLineEntity(
  key: 'l1',
  product: CatalogProductEntity(id: 'p1', slug: 'p1', name: 'Rice'),
  quantity: 2,
  unitPriceFils: 600,
  compareAtFils: 800,
  lineTotalFils: 1200,
);

/// A priced basket: 0.400 item savings, 0.300 coupon, 0.100 points, free
/// delivery on a 0.500 list fee.
const CartEntity _rich = CartEntity(
  lines: <CartLineEntity>[_line],
  coupon: CartCouponEntity(code: 'SAVE3', discountFils: 300),
  loyalty: CartLoyaltyEntity(pointsApplied: 100, discountFils: 100),
  totals: CartTotalsEntity(
    subtotalFils: 1200,
    couponDiscountFils: 300,
    loyaltyDiscountFils: 100,
    discountFils: 400,
    freeDelivery: true,
    baseDeliveryFeeFils: 500,
    totalFils: 800,
    minOrderFils: 2500,
  ),
);

CheckoutBarFacts _facts({
  CartEntity cart = _rich,
  CheckoutOfferHints hints = CheckoutOfferHints.none,
  bool quoted = true,
  bool updating = false,
  CheckoutBlockReason? reason,
}) => CheckoutBarFacts.of(
  cart: cart,
  savings: CartSavings.of(cart),
  hints: hints,
  quoted: quoted,
  updating: updating,
  reason: reason,
);

void main() {
  test('an empty basket says nothing', () {
    expect(_facts(cart: const CartEntity()), CheckoutBarFacts.none);
  });

  test('an unquoted destination pins "choose an address"', () {
    final facts = _facts(quoted: false);

    expect(facts.pinned?.kind, CheckoutBarFactKind.chooseDestination);
    expect(facts.rotating, isEmpty);
  });

  test('a blocking reason is pinned alone', () {
    final facts = _facts(reason: CheckoutBlockReason.payment);

    expect(facts.pinned?.kind, CheckoutBarFactKind.blocked);
    expect(facts.pinned?.reason, CheckoutBlockReason.payment);
    expect(facts.rotating, isEmpty);
  });

  test('a minimum-order block carries the shortfall', () {
    const below = CartEntity(
      lines: <CartLineEntity>[_line],
      totals: CartTotalsEntity(
        subtotalFils: 1200,
        totalFils: 1700,
        minOrderFils: 2500,
        meetsMinOrder: false,
      ),
    );
    final facts = _facts(cart: below, reason: CheckoutBlockReason.minOrder);

    expect(facts.pinned?.fils, 1300);
    expect(facts.pinned?.kd, 1.3);
  });

  test('destination, slot and empty are handled by the page, not pinned', () {
    for (final reason in const <CheckoutBlockReason>[
      CheckoutBlockReason.destination,
      CheckoutBlockReason.slot,
      CheckoutBlockReason.empty,
    ]) {
      expect(_facts(reason: reason).pinned, isNull, reason: '$reason');
    }
  });

  test('the positive facts rotate, true ones only, in order', () {
    final facts = _facts(
      hints: const CheckoutOfferHints(freeDeliveryGapFils: 900),
    );

    expect(facts.pinned, isNull);
    expect(facts.rotating.map((fact) => fact.kind), <CheckoutBarFactKind>[
      CheckoutBarFactKind.totalSavings,
      CheckoutBarFactKind.couponSaved,
      CheckoutBarFactKind.pointsSaved,
      CheckoutBarFactKind.freeDelivery,
      CheckoutBarFactKind.freeDeliveryGap,
    ]);
    // 0.400 items + 0.400 discounts + 0.500 waived delivery.
    expect(facts.rotating.first.fils, 1300);
    expect(facts.rotating[1].code, 'SAVE3');
    expect(facts.rotating[1].fils, 300);
    expect(facts.rotating[2].fils, 100);
  });

  test('every saving together is hidden while the cart updates', () {
    final facts = _facts(updating: true);

    expect(
      facts.rotating.map((fact) => fact.kind),
      isNot(contains(CheckoutBarFactKind.totalSavings)),
    );
    expect(
      facts.rotating.map((fact) => fact.kind),
      contains(CheckoutBarFactKind.couponSaved),
    );
  });

  test('a fact keeps its id when only its amount changes', () {
    const a = CheckoutBarFact(CheckoutBarFactKind.totalSavings, fils: 100);
    const b = CheckoutBarFact(CheckoutBarFactKind.totalSavings, fils: 200);
    const blocked = CheckoutBarFact.blocked(CheckoutBlockReason.offline);

    expect(a.id, b.id);
    expect(a, isNot(b));
    expect(blocked.id, isNot(a.id));
    expect(blocked.kind, CheckoutBarFactKind.blocked);
    expect(blocked.reason, CheckoutBlockReason.offline);
  });

  test('a blocked fact cannot be built without its reason', () {
    // Built at run time (a const one would not even compile).
    final kind = CheckoutBarFactKind.values.byName('blocked');
    expect(() => CheckoutBarFact(kind), throwsA(isA<AssertionError>()));
  });

  test('"Free delivery" only when no delivery fee is still charged, like '
      'the receipt', () {
    const charged = CartEntity(
      lines: <CartLineEntity>[_line],
      totals: CartTotalsEntity(
        subtotalFils: 1200,
        freeDelivery: true,
        deliveryFeeFils: 500,
        baseDeliveryFeeFils: 500,
        totalFils: 1700,
      ),
    );

    expect(
      _facts(cart: charged).rotating.map((fact) => fact.kind),
      isNot(contains(CheckoutBarFactKind.freeDelivery)),
    );
  });
}
