import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_cart_facts.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_payment_choice.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';

void main() {
  const covers = CheckoutCartFacts(walletFils: 5000, totalFils: 2600);
  const short = CheckoutCartFacts(walletFils: 1000, totalFils: 2600);
  const guest = CheckoutCartFacts(totalFils: 0);
  const codOff = CheckoutStoreRules(codEnabled: false);
  const prefersWallet = CheckoutStoreRules(
    defaultPaymentMethod: OrderPaymentMethod.wallet,
  );

  group('onRules', () {
    OrderPaymentMethod? onRules(
      CheckoutStoreRules rules,
      CheckoutCartFacts cart, [
      OrderPaymentMethod current = OrderPaymentMethod.cod,
    ]) => CheckoutPaymentChoice.onRules(
      rules: rules,
      current: current,
      cart: cart,
    );

    test('cash off + a covering wallet → wallet', () {
      expect(onRules(codOff, covers), OrderPaymentMethod.wallet);
    });

    test('the store prefers the wallet + it covers → wallet', () {
      expect(onRules(prefersWallet, covers), OrderPaymentMethod.wallet);
    });

    test('otherwise the choice stays', () {
      expect(onRules(CheckoutStoreRules.unknown, covers), isNull);
      expect(onRules(codOff, short), isNull);
      expect(onRules(prefersWallet, short), isNull);
      expect(onRules(codOff, guest), isNull, reason: 'a guest has no wallet');
      expect(onRules(codOff, covers, OrderPaymentMethod.wallet), isNull);
    });
  });

  group('onTotal', () {
    OrderPaymentMethod? onTotal(
      CheckoutStoreRules rules,
      CheckoutCartFacts cart, [
      OrderPaymentMethod current = OrderPaymentMethod.wallet,
    ]) => CheckoutPaymentChoice.onTotal(
      rules: rules,
      current: current,
      cart: cart,
    );

    test('a short wallet falls back to cash when the store takes it', () {
      expect(
        onTotal(CheckoutStoreRules.unknown, short),
        OrderPaymentMethod.cod,
      );
    });

    test('a short wallet stays when cash is off (the order is blocked)', () {
      expect(onTotal(codOff, short), isNull);
    });

    test('a covering wallet, or cash already, stays', () {
      expect(onTotal(CheckoutStoreRules.unknown, covers), isNull);
      expect(
        onTotal(CheckoutStoreRules.unknown, short, OrderPaymentMethod.cod),
        isNull,
      );
    });
  });
}
