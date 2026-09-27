// LoyaltyProgram's one redeem rule (shared by the account screens and the
// checkout): who may redeem, what the points are worth on this basket and
// how many to send.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/loyalty_program.dart';

void main() {
  /// The live programme: 1 fils a point, from 100 points.
  const program = LoyaltyProgram(
    enabled: true,
    redemptionPerPoint: 1,
    minRedeemPoints: 100,
  );

  /// 2.100 of goods, 0.300 off with a coupon, 0.200 off with an offer.
  const totals = CartTotalsEntity(
    subtotalFils: 2100,
    couponDiscountFils: 300,
    offerDiscountFils: 200,
    discountFils: 500,
    totalFils: 1600,
  );

  group('canRedeem', () {
    test('a running programme with enough points', () {
      expect(program.canRedeem(100), isTrue);
      expect(program.canRedeem(5000), isTrue);
    });

    test('not when the programme is off', () {
      expect(
        const LoyaltyProgram(redemptionPerPoint: 1).canRedeem(5000),
        isFalse,
      );
    });

    test('not below the minimum, nor with no points', () {
      expect(program.canRedeem(99), isFalse);
      expect(program.canRedeem(0), isFalse);
    });

    test('not when a point is worth nothing', () {
      expect(
        const LoyaltyProgram(enabled: true, minRedeemPoints: 1).canRedeem(50),
        isFalse,
      );
    });
  });

  test(
    'isBelowMinimum: a running programme, some points, under the minimum',
    () {
      expect(program.isBelowMinimum(99), isTrue);
      expect(program.isBelowMinimum(100), isFalse);
      expect(program.isBelowMinimum(0), isFalse);
      expect(
        const LoyaltyProgram(
          redemptionPerPoint: 1,
          minRedeemPoints: 100,
        ).isBelowMinimum(50),
        isFalse,
      );
      expect(
        const LoyaltyProgram(
          enabled: true,
          minRedeemPoints: 100,
        ).isBelowMinimum(50),
        isFalse,
      );
    },
  );

  test('payableFils is the goods after the coupon and the offers', () {
    expect(program.payableFils(totals), 1600);
    expect(
      program.payableFils(
        const CartTotalsEntity(subtotalFils: 100, couponDiscountFils: 300),
      ),
      0,
    );
  });

  test('worthFils is capped at what is left to pay', () {
    expect(program.worthFils(500, totals), 500);
    expect(program.worthFils(5000, totals), 1600);
  });

  group('pointsToRedeem', () {
    test('enough to cover the payable amount, within the balance', () {
      expect(program.pointsToRedeem(5000, totals), 1600);
    });

    test('never more than the balance', () {
      expect(program.pointsToRedeem(700, totals), 700);
    });

    test('at least the minimum', () {
      expect(
        program.pointsToRedeem(
          500,
          const CartTotalsEntity(subtotalFils: 40, totalFils: 40),
        ),
        100,
      );
    });

    test('rounds up to cover a fraction of a point', () {
      const tens = LoyaltyProgram(
        enabled: true,
        redemptionPerPoint: 10,
        minRedeemPoints: 1,
      );
      expect(
        tens.pointsToRedeem(
          1000,
          const CartTotalsEntity(subtotalFils: 1005, totalFils: 1005),
        ),
        101,
      );
    });

    test('0 when the customer cannot redeem', () {
      expect(program.pointsToRedeem(50, totals), 0);
      expect(LoyaltyProgram.none.pointsToRedeem(5000, totals), 0);
    });

    test('0 when nothing is left to pay: the minimum is never spent for '
        'nothing', () {
      // The coupon and the offers cover the goods.
      const covered = CartTotalsEntity(
        subtotalFils: 1000,
        couponDiscountFils: 600,
        offerDiscountFils: 400,
        discountFils: 1000,
        deliveryFeeFils: 500,
        totalFils: 500,
      );

      expect(program.canRedeem(5000), isTrue);
      expect(program.canRedeemOn(5000, covered), isFalse);
      expect(program.canRedeemOn(5000, totals), isTrue);
      expect(program.worthFils(5000, covered), 0);
      expect(program.pointsToRedeem(5000, covered), 0);
    });
  });

  test('worthKd is worthFils in dinar', () {
    expect(program.worthKd(500, totals), 0.5);
    expect(program.worthKd(5000, totals), 1.6);
  });
}
