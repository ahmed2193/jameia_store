import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';

void main() {
  group('CartTotalsEntity delivery fee', () {
    test('the express surcharge is taken out of the delivery part', () {
      const totals = CartTotalsEntity(
        subtotalFils: 2100,
        deliveryFeeFils: 1250, // the server folds express into this
        baseDeliveryFeeFils: 500,
        expressSurchargeFils: 750,
        totalFils: 3350,
      );

      expect(totals.deliveryFeeWithoutExpressFils, 500);
      // Delivery + express is exactly what the server charges for delivery,
      // so a summary listing both rows adds up to the total.
      expect(
        totals.deliveryFeeWithoutExpressFils + totals.expressSurchargeFils,
        totals.deliveryFeeFils,
      );
    });

    test('a free delivery that still carries express never goes negative', () {
      const totals = CartTotalsEntity(
        deliveryFeeFils: 0,
        baseDeliveryFeeFils: 500, // the branch's list price, not charged
        expressSurchargeFils: 750,
        freeDelivery: true,
      );

      expect(totals.deliveryFeeWithoutExpressFils, 0);
    });

    test('no express leaves the delivery fee alone', () {
      const totals = CartTotalsEntity(deliveryFeeFils: 500);

      expect(totals.deliveryFeeWithoutExpressFils, 500);
      expect(totals.deliveryFeeWithoutExpressKd, 0.5);
    });
  });
}
