import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_coupon_drop.dart';

CartEntity _cart([CartCouponEntity? coupon]) => CartEntity(coupon: coupon);

void main() {
  const saving = CartCouponEntity(code: 'SAVE3', discountFils: 300);

  test('the coupon disappeared: dropped', () {
    expect(CheckoutCouponDrop.droppedCode(_cart(saving), _cart()), 'SAVE3');
  });

  test('the same code stopped saving: dropped', () {
    expect(
      CheckoutCouponDrop.droppedCode(
        _cart(saving),
        _cart(const CartCouponEntity(code: 'SAVE3')),
      ),
      'SAVE3',
    );
  });

  test('no coupon before, the same saving, or a new code: not dropped', () {
    expect(CheckoutCouponDrop.droppedCode(_cart(), _cart(saving)), isNull);
    expect(
      CheckoutCouponDrop.droppedCode(_cart(saving), _cart(saving)),
      isNull,
    );
    expect(
      CheckoutCouponDrop.droppedCode(
        _cart(saving),
        _cart(const CartCouponEntity(code: 'OTHER', discountFils: 100)),
      ),
      isNull,
    );
    // A code that never saved anything did not "stop" saving.
    const zero = CartCouponEntity(code: 'ZERO');
    expect(CheckoutCouponDrop.droppedCode(_cart(zero), _cart(zero)), isNull);
  });
}
