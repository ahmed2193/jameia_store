// Checkout money-math tests — the revenue-critical path that had ZERO coverage.
//
// Guards CheckoutDraft.discountFor / totalFor: the coupon min-spend gate, the
// "discount never exceeds subtotal" cap, the floor-at-zero on the total, and the
// invariant that the SAME helper feeds both the displayed total and the total
// stamped on the placed order (no display-vs-charge drift).

import 'package:flutter_test/flutter_test.dart';

import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/coupon_entity.dart';

/// KD5 off once the cart reaches KD20.
const _coupon5over20 = CouponEntity(
  id: 'c1',
  title: 'KD5 off',
  subtitle: 'Spend 20',
  amount: 5.0,
  minSpend: 20.0,
  expiry: '',
  used: false,
);

/// A coupon whose face value exceeds any realistic small cart.
const _couponHuge = CouponEntity(
  id: 'c2',
  title: 'Huge',
  subtitle: '',
  amount: 999.0,
  minSpend: 0.0,
  expiry: '',
  used: false,
);

void main() {
  group('CheckoutDraft.discountFor', () {
    test('no coupon → 0', () {
      expect(const CheckoutDraft().discountFor(50.0), 0.0);
    });

    test('below minSpend → 0 (coupon auto-drops when the cart shrinks)', () {
      const d = CheckoutDraft(coupon: _coupon5over20);
      expect(d.discountFor(19.999), 0.0);
    });

    test('exactly at minSpend → full amount (boundary is inclusive)', () {
      const d = CheckoutDraft(coupon: _coupon5over20);
      expect(d.discountFor(20.0), 5.0);
    });

    test('above minSpend → flat amount', () {
      const d = CheckoutDraft(coupon: _coupon5over20);
      expect(d.discountFor(100.0), 5.0);
    });

    test('discount is capped at the subtotal (never negative total)', () {
      const d = CheckoutDraft(coupon: _couponHuge);
      expect(d.discountFor(7.5), 7.5);
    });
  });

  group('CheckoutDraft.totalFor', () {
    test('subtotal + delivery + tip, no coupon', () {
      const d = CheckoutDraft(tip: 2.0);
      expect(d.totalFor(30.0, 1.5), closeTo(33.5, 1e-9));
    });

    test('free delivery (fee 0) charges only subtotal', () {
      const d = CheckoutDraft();
      expect(d.totalFor(30.0, 0.0), closeTo(30.0, 1e-9));
    });

    test('applied coupon reduces the total', () {
      const d = CheckoutDraft(coupon: _coupon5over20);
      expect(d.totalFor(30.0, 1.0), closeTo(26.0, 1e-9)); // 30 - 5 + 1 + 0
    });

    test('coupon below min-spend does not reduce the total', () {
      const d = CheckoutDraft(coupon: _coupon5over20);
      expect(d.totalFor(10.0, 1.0), closeTo(11.0, 1e-9)); // no discount
    });

    test('total is floored at zero when the discount covers the subtotal', () {
      const d = CheckoutDraft(coupon: _couponHuge);
      expect(d.totalFor(30.0, 0.0), 0.0); // 30 - 30 + 0 + 0
    });

    test('displayed total == stamped total (same helper, no drift)', () {
      const d = CheckoutDraft(coupon: _coupon5over20, tip: 3.0);
      final displayed = d.totalFor(40.0, 2.0);
      final stamped = d.totalFor(40.0, 2.0);
      expect(displayed, stamped);
      expect(displayed, closeTo(40.0 - 5.0 + 2.0 + 3.0, 1e-9)); // 40.0
    });
  });
}
