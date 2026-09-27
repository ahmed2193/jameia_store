// PlaceOrderUseCase owns whether an order may go: every block reason is
// checked on the full facts before `POST /v1/orders`, and none can be
// skipped by leaving the cart facts out (they are required).
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_block_reason.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_cart_facts.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/place_order_usecase.dart';

import '../fake_checkout_repository.dart';

void main() {
  late FakeCheckoutRepository repository;
  late PlaceOrderUseCase placeOrder;

  setUp(() {
    repository = FakeCheckoutRepository();
    placeOrder = PlaceOrderUseCase(repository);
  });

  const draft = CheckoutDraft(addressId: 'a1');
  const cart = CheckoutCartFacts(totalFils: 2600);

  PlaceOrderParams params({
    CheckoutDraft draft = draft,
    bool hasSelection = true,
    CheckoutStoreRules rules = CheckoutStoreRules.unknown,
    CheckoutCartFacts cart = cart,
  }) => PlaceOrderParams(
    draft: draft,
    hasSelection: hasSelection,
    rules: rules,
    cart: cart,
  );

  test('an order nothing blocks goes to the server', () async {
    final result = await placeOrder(params());

    expect(result.isRight(), isTrue);
    expect(repository.calls, <String>['place:cod']);
  });

  final blocked = <String, (PlaceOrderParams, CheckoutBlockReason)>{
    'no destination': (
      params(draft: const CheckoutDraft()),
      CheckoutBlockReason.destination,
    ),
    'a destination the server has not resolved': (
      params(hasSelection: false),
      CheckoutBlockReason.destination,
    ),
    'maintenance': (
      params(rules: const CheckoutStoreRules(maintenance: true)),
      CheckoutBlockReason.maintenance,
    ),
    'a cart block': (
      params(
        cart: const CheckoutCartFacts(block: CartCheckoutBlock.belowMinOrder),
      ),
      CheckoutBlockReason.minOrder,
    ),
    'a wallet that does not cover the total': (
      params(
        draft: const CheckoutDraft(
          addressId: 'a1',
          paymentMethod: OrderPaymentMethod.wallet,
        ),
        cart: const CheckoutCartFacts(walletFils: 1000, totalFils: 2600),
      ),
      CheckoutBlockReason.payment,
    ),
    'cash on delivery while the store turned it off': (
      params(rules: const CheckoutStoreRules(codEnabled: false)),
      CheckoutBlockReason.payment,
    ),
  };
  for (final MapEntry(key: name, value: (input, reason)) in blocked.entries) {
    test('blocked, never sent: $name', () async {
      final result = await placeOrder(input);

      expect(input.blockReason, reason);
      expect(
        result.fold((failure) => failure, (_) => null),
        ValidationFailure(reason.name),
      );
      expect(repository.calls, isEmpty);
    });
  }
}
