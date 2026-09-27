import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_savings_summary.dart';

CheckoutSavingsSummary _of({
  String? code,
  int coupon = 0,
  int offers = 0,
  int points = 0,
}) => CheckoutSavingsSummary.of(
  CartEntity(
    coupon: code == null ? null : CartCouponEntity(code: code),
    totals: CartTotalsEntity(
      couponDiscountFils: coupon,
      offerDiscountFils: offers,
      loyaltyDiscountFils: points,
      discountFils: coupon + offers + points,
    ),
  ),
);

void main() {
  test('nothing applied: add a code', () {
    expect(_of(), const CheckoutSavingsSummary());
    // Points have their own row: they never count here.
    expect(_of(points: 500).kind, CheckoutSavingsKind.none);
  });

  test('a coupon that saves', () {
    final summary = _of(code: 'SAVE3', coupon: 300);

    expect(summary.kind, CheckoutSavingsKind.code);
    expect(summary.code, 'SAVE3');
    expect(summary.fils, 300);
    expect(summary.kd, 0.3);
  });

  test('a coupon that saves nothing on this basket', () {
    final summary = _of(code: 'SAVE3');

    expect(summary.kind, CheckoutSavingsKind.codeNoSaving);
    expect(summary.code, 'SAVE3');
    expect(summary.fils, 0);
  });

  test('offers only', () {
    final summary = _of(offers: 650);

    expect(summary.kind, CheckoutSavingsKind.offers);
    expect(summary.fils, 650);
  });

  test('a coupon and offers: saved together', () {
    final summary = _of(code: 'SAVE3', coupon: 300, offers: 650, points: 100);

    expect(summary.kind, CheckoutSavingsKind.combined);
    expect(summary.fils, 950);
    expect(summary.code, 'SAVE3');
  });
}
