import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/delivery_slot_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_block_reason.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_cart_facts.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';

void main() {
  const ready = CheckoutDraft(addressId: 'a1');
  const slot = DeliverySlotEntity(templateId: 't1', date: '2026-09-22');

  CheckoutBlockReason? resolve({
    CheckoutDraft draft = ready,
    bool hasSelection = true,
    CheckoutStoreRules rules = CheckoutStoreRules.unknown,
    CheckoutCartFacts cart = const CheckoutCartFacts(totalFils: 2600),
  }) => CheckoutBlockReason.resolve(
    draft: draft,
    hasSelection: hasSelection,
    rules: rules,
    cart: cart,
  );

  test('nothing missing: the order can go', () {
    expect(resolve(), isNull);
  });

  test('the full order: maintenance first … payment last', () {
    // Everything wrong at once, then fixed one by one.
    var rules = const CheckoutStoreRules(maintenance: true, codEnabled: false);
    var draft = const CheckoutDraft(timing: DeliveryTiming.scheduled);
    var hasSelection = false;
    var cart = const CheckoutCartFacts(
      unsynced: true,
      block: CartCheckoutBlock.empty,
      totalFils: 2600,
    );
    CheckoutBlockReason? now() => resolve(
      draft: draft,
      hasSelection: hasSelection,
      rules: rules,
      cart: cart,
    );

    expect(now(), CheckoutBlockReason.maintenance);
    rules = const CheckoutStoreRules(codEnabled: false);
    expect(now(), CheckoutBlockReason.destination);
    draft = draft.copyWith(addressId: 'a1');
    expect(now(), CheckoutBlockReason.destination, reason: 'not resolved');
    hasSelection = true;
    expect(now(), CheckoutBlockReason.slot);
    draft = draft.copyWith(slot: slot, notes: 'x' * 300);
    expect(now(), CheckoutBlockReason.notesTooLong);
    draft = draft.copyWith(notes: '');
    expect(now(), CheckoutBlockReason.offline);
    cart = const CheckoutCartFacts(
      block: CartCheckoutBlock.empty,
      totalFils: 2600,
    );
    expect(now(), CheckoutBlockReason.empty);
    cart = const CheckoutCartFacts(
      block: CartCheckoutBlock.lineIssue,
      totalFils: 2600,
    );
    expect(now(), CheckoutBlockReason.lineIssue);
    cart = const CheckoutCartFacts(totalFils: 2600);
    expect(now(), CheckoutBlockReason.payment);
    rules = CheckoutStoreRules.unknown;
    expect(now(), isNull);
  });

  test('the cart blocks map one to one', () {
    for (final (block, reason)
        in const <(CartCheckoutBlock, CheckoutBlockReason)>[
          (CartCheckoutBlock.empty, CheckoutBlockReason.empty),
          (CartCheckoutBlock.lineIssue, CheckoutBlockReason.lineIssue),
          (CartCheckoutBlock.belowMinOrder, CheckoutBlockReason.minOrder),
          (CartCheckoutBlock.branchClosed, CheckoutBlockReason.branchClosed),
          (CartCheckoutBlock.noCapacity, CheckoutBlockReason.capacity),
        ]) {
      expect(
        resolve(cart: CheckoutCartFacts(block: block, totalFils: 2600)),
        reason,
      );
    }
  });

  test('cash on delivery while the store turned it off is blocked, whatever '
      'the wallet', () {
    expect(
      resolve(
        rules: const CheckoutStoreRules(codEnabled: false),
        cart: const CheckoutCartFacts(walletFils: 99000, totalFils: 2600),
      ),
      CheckoutBlockReason.payment,
    );
  });

  test('a wallet short of the total is blocked; one that covers it is not', () {
    const wallet = CheckoutDraft(
      addressId: 'a1',
      paymentMethod: OrderPaymentMethod.wallet,
    );

    expect(
      resolve(
        draft: wallet,
        cart: const CheckoutCartFacts(walletFils: 1000, totalFils: 2600),
      ),
      CheckoutBlockReason.payment,
    );
    expect(
      resolve(
        draft: wallet,
        cart: const CheckoutCartFacts(walletFils: 2600, totalFils: 2600),
      ),
      isNull,
    );
  });

  test('an unknown payment method is blocked', () {
    expect(
      resolve(
        draft: const CheckoutDraft(
          addressId: 'a1',
          paymentMethod: OrderPaymentMethod.other,
        ),
      ),
      CheckoutBlockReason.payment,
    );
  });

  test('pickup needs a branch', () {
    expect(
      resolve(draft: const CheckoutDraft(mode: FulfillmentMode.pickup)),
      CheckoutBlockReason.destination,
    );
    expect(
      resolve(
        draft: const CheckoutDraft(
          mode: FulfillmentMode.pickup,
          branchId: 'b1',
        ),
      ),
      isNull,
    );
  });
}
