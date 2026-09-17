import 'package:equatable/equatable.dart';

import 'coupon_entity.dart';

/// Drop-off choices mirror Jameia's `HAND_TO_ME` / `LEAVE_AT_DESIGNATED_SPOT`.
enum DropOffOption { handToMe, leaveAtSpot }

/// Payment methods mirror the order_confirm payment-row asset set.
enum PaymentMethod { cod, applePay, googlePay }

/// The checkout order draft — the user's in-progress selections on the
/// `order_confirm_global` screen (coupon, drop-off preference, cutlery toggle,
/// rider tip, payment method) plus the derived money math (coupon discount +
/// order total) computed against the live cart subtotal.
///
/// The subtotal and delivery fee are NOT part of the draft (they belong to the
/// cart + shop); the derived-total helpers take them as arguments so the draft
/// stays a pure snapshot of the user's checkout choices.
class CheckoutDraft extends Equatable {
  const CheckoutDraft({
    this.coupon,
    this.dropOff = DropOffOption.handToMe,
    this.cutlery = false,
    this.tip = 0,
    this.payMethod = PaymentMethod.cod,
  });

  /// The applied coupon, or null when none is selected.
  final CouponEntity? coupon;
  final DropOffOption dropOff;
  final bool cutlery;
  final double tip;
  final PaymentMethod payMethod;

  /// Discount applied by the selected coupon — a flat [Coupon.amount] once the
  /// [Coupon.minSpend] gate is met, never more than the subtotal. Returns 0 when
  /// no coupon is applied or the cart is below the coupon's minimum (so a coupon
  /// auto-drops if the cart shrinks below its threshold).
  double discountFor(double subtotal) {
    final c = coupon;
    if (c == null || subtotal < c.minSpend) return 0;
    return c.amount < subtotal ? c.amount : subtotal;
  }

  /// Order total: subtotal − discount + delivery + tip, floored at zero.
  double totalFor(double subtotal, double deliveryFee) =>
      (subtotal - discountFor(subtotal) + deliveryFee + tip).clamp(
        0.0,
        double.infinity,
      );

  CheckoutDraft copyWith({
    CouponEntity? coupon,
    DropOffOption? dropOff,
    bool? cutlery,
    double? tip,
    PaymentMethod? payMethod,
  }) => CheckoutDraft(
    coupon: coupon ?? this.coupon,
    dropOff: dropOff ?? this.dropOff,
    cutlery: cutlery ?? this.cutlery,
    tip: tip ?? this.tip,
    payMethod: payMethod ?? this.payMethod,
  );

  @override
  List<Object?> get props => [coupon, dropOff, cutlery, tip, payMethod];
}
