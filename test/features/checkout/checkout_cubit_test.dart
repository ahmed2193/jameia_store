import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/delivery_slot_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_block_reason.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_cart_facts.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_state.dart';

import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCheckoutRepository repository;

  /// A settled cart that can be ordered, paid on delivery.
  const ready = CheckoutCartFacts(totalFils: 2600);

  CheckoutCubit build() {
    repository = FakeCheckoutRepository();
    return buildCheckoutCubit(repository);
  }

  /// What `CheckoutBlockReason` says about the cubit's current state, for
  /// a cart that can be ordered.
  CheckoutBlockReason? reasonOf(
    CheckoutCubit cubit, [
    CheckoutCartFacts cart = const CheckoutCartFacts(),
  ]) => CheckoutBlockReason.resolve(
    draft: cubit.state.draft,
    hasSelection: cubit.state.hasSelection,
    rules: cubit.state.rules,
    cart: cart,
  );

  test('start loads pickup branches and the store rules, no slots', () async {
    final cubit = build();

    await cubit.start();

    expect(cubit.state.status, CheckoutStatus.ready);
    expect(cubit.state.branches.map((branch) => branch.id), <String>['b1']);
    expect(cubit.state.rules.storeName, 'Jm3eia');
    expect(cubit.state.rules.loyalty.minRedeemPoints, 100);
    // The slots route answers only once the cart has a destination.
    expect(repository.calls, isNot(contains('slots')));
    expect(cubit.state.slotDays, isEmpty);
    expect(cubit.state.hasScheduledSlots, isFalse);
    await cubit.close();
  });

  test(
    'the bookable days load after the default address is selected',
    () async {
      final cubit = build();

      await cubit.start(defaultAddressId: 'a1');

      expect(
        repository.calls,
        containsAllInOrder(<String>['address:a1', 'slots']),
      );
      expect(cubit.state.slotDays, hasLength(1));
      expect(cubit.state.hasScheduledSlots, isTrue);
      await cubit.close();
    },
  );

  test('the default address is selected on the server right away', () async {
    final cubit = build();

    await cubit.start(defaultAddressId: 'a1');

    expect(repository.calls, contains('address:a1'));
    expect(cubit.state.selection?.addressId, 'a1');
    expect(cubit.state.draft.addressId, 'a1');
    await cubit.close();
  });

  test('a load failure shows the error view and can be retried', () async {
    final cubit = build();
    repository.branchesFailure = const NetworkFailure();

    await cubit.start();

    expect(cubit.state.status, CheckoutStatus.error);
    expect(cubit.state.loadFailure, isA<NetworkFailure>());

    await cubit.retry();
    expect(cubit.state.status, CheckoutStatus.ready);
    await cubit.close();
  });

  test('unreadable store rules still open the page, on the defaults', () async {
    final cubit = build();
    repository.rulesFailure = const NetworkFailure();

    await cubit.start();

    expect(cubit.state.status, CheckoutStatus.ready);
    expect(cubit.state.rules, CheckoutStoreRules.unknown);
    expect(cubit.state.rules.codEnabled, isTrue);
    await cubit.close();
  });

  test('a selection that lands after a newer one is dropped', () async {
    final cubit = build();
    await cubit.start();

    final gate = Completer<void>();
    repository.selectGate = gate;
    final stale = cubit.selectAddress('a1');
    await Future<void>.delayed(Duration.zero);
    await cubit.selectAddress('a2'); // newer choice wins
    gate.complete();
    await stale;

    expect(cubit.state.selection?.addressId, 'a2');
    expect(cubit.state.isSelecting, isFalse);
    await cubit.close();
  });

  test('switching to pickup re-selects the known branch', () async {
    final cubit = build();
    await cubit.start();
    await cubit.selectBranch('b1');
    await cubit.setMode(FulfillmentMode.delivery);
    repository.calls.clear();

    await cubit.setMode(FulfillmentMode.pickup);

    expect(repository.calls, <String>['branch:b1']);
    expect(cubit.state.draft.isPickup, isTrue);
    await cubit.close();
  });

  test(
    'switching to a mode with no destination clears the selection',
    () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');

      await cubit.setMode(FulfillmentMode.pickup);

      expect(cubit.state.selection, isNull);
      expect(reasonOf(cubit), CheckoutBlockReason.destination);
      await cubit.close();
    },
  );

  test('the order cannot be placed before a destination is chosen', () async {
    final cubit = build();
    await cubit.start();

    await cubit.placeOrder(ready);

    expect(repository.calls, isNot(contains('place:cod')));
    expect(cubit.state.status, CheckoutStatus.ready);
    await cubit.close();
  });

  test('a second tap while placing is ignored', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');
    final gate = Completer<void>();
    repository.placeGate = gate;

    final first = cubit.placeOrder(ready);
    await cubit.placeOrder(ready); // refused: already placing

    expect(cubit.state.isPlacing, isTrue);
    expect(cubit.state.canPlace, isFalse);
    gate.complete();
    await first;

    expect(
      repository.calls.where((call) => call.startsWith('place')),
      hasLength(1),
    );
    expect(cubit.state.status, CheckoutStatus.placed);
    expect(cubit.state.placedOrder?.id, 'o1');
    await cubit.close();
  });

  test('a rejected order stays on the page with its failure', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');
    repository.placeFailure = const ServerFailure(
      'cart empty',
      statusCode: 400,
    );

    await cubit.placeOrder(ready);

    expect(cubit.state.status, CheckoutStatus.ready);
    expect(cubit.state.isPlacing, isFalse);
    expect(cubit.state.failedAction, CheckoutAction.place);
    expect(cubit.state.requiresSignIn, isFalse);
    await cubit.close();
  });

  test('a scheduled order without a slot is blocked on the slot', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');

    cubit.setTiming(DeliveryTiming.scheduled);
    expect(reasonOf(cubit), CheckoutBlockReason.slot);
    await cubit.placeOrder(ready);
    expect(repository.calls, isNot(contains('place:cod')));

    cubit.setSlot(cubit.state.slotDays.single.slots.single);
    expect(reasonOf(cubit), isNull);
    expect(cubit.state.canPlace, isTrue);

    cubit.setTiming(DeliveryTiming.asap);
    expect(cubit.state.draft.slot, isNull);
    await cubit.close();
  });

  test('the payment method and notes reach the draft', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');

    cubit
      ..setPaymentMethod(OrderPaymentMethod.wallet)
      ..setNotes('leave at the door');
    await cubit.placeOrder(
      const CheckoutCartFacts(walletFils: 5000, totalFils: 2600),
    );

    expect(repository.calls, contains('place:wallet'));
    expect(cubit.state.draft.notes, 'leave at the door');
    await cubit.close();
  });

  test('a cart that already has express opens on the express option', () async {
    final cubit = build();

    // Express is a flag the SERVER keeps on the cart, so a customer who
    // switched it on there is already paying for it when this page opens.
    await cubit.start(expressSelected: true);

    expect(cubit.state.draft.timing, DeliveryTiming.express);
    await cubit.close();
  });

  test('a cart without express opens on ASAP', () async {
    final cubit = build();

    await cubit.start();

    expect(cubit.state.draft.timing, DeliveryTiming.asap);
    await cubit.close();
  });

  test('a second start while the first is loading is ignored', () async {
    final cubit = build();
    final gate = Completer<void>();
    repository.loadGate = gate;

    final first = cubit.start();
    final second = cubit.start(); // a double tap on "retry"
    gate.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.calls.where((call) => call == 'branches'), hasLength(1));
    expect(cubit.state.status, CheckoutStatus.ready);
    await cubit.close();
  });

  group('B1: a refused destination puts the previous one back', () {
    test('address', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      repository.selectFailure = const ServerFailure('zone', statusCode: 400);

      await cubit.selectAddress('a2');

      expect(cubit.state.draft.addressId, 'a1');
      expect(cubit.state.selection?.addressId, 'a1');
      expect(cubit.state.isSelecting, isFalse);
      expect(cubit.state.failedAction, CheckoutAction.select);
      await cubit.close();
    });

    test('branch (pickup keeps no stale branch)', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      repository.selectFailure = const NetworkFailure();

      await cubit.selectBranch('b1');

      // Back on delivery to a1: the server still holds that selection.
      expect(cubit.state.draft.mode, FulfillmentMode.delivery);
      expect(cubit.state.draft.branchId, isNull);
      expect(cubit.state.draft.addressId, 'a1');
      expect(cubit.state.selection?.addressId, 'a1');
      await cubit.close();
    });

    test('timing, slot, payment and notes are kept', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      final slot = cubit.state.slotDays.single.slots.single;
      cubit
        ..setSlot(slot)
        ..setPaymentMethod(OrderPaymentMethod.wallet)
        ..setNotes('ring twice');
      repository.selectFailure = const NetworkFailure();

      await cubit.selectAddress('a2');

      expect(cubit.state.draft.addressId, 'a1');
      expect(cubit.state.draft.slot, slot);
      expect(cubit.state.draft.paymentMethod, OrderPaymentMethod.wallet);
      expect(cubit.state.draft.notes, 'ring twice');
      await cubit.close();
    });
  });

  test('a 401 on a selection asks for sign-in and blocks placing', () async {
    final cubit = build();
    await cubit.start();
    repository.selectFailure = const UnauthorizedFailure();

    await cubit.selectAddress('a1');

    expect(cubit.state.requiresSignIn, isTrue);
    expect(cubit.state.canPlace, isFalse);
    // Sticky: a later state keeps it.
    cubit.setNotes('x');
    expect(cubit.state.requiresSignIn, isTrue);
    await cubit.close();
  });

  test('a 401 on placing asks for sign-in', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');
    repository.placeFailure = const UnauthorizedFailure();

    await cubit.placeOrder(ready);

    expect(cubit.state.requiresSignIn, isTrue);
    expect(cubit.state.failedAction, CheckoutAction.place);
    await cubit.close();
  });

  group('B2: the windows follow the delivery selection', () {
    test('a failed slots read is not fatal: no windows offered', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      expect(cubit.state.hasScheduledSlots, isTrue);
      repository.slotsFailure = const NetworkFailure();

      await cubit.selectAddress('a2');

      expect(cubit.state.status, CheckoutStatus.ready);
      expect(cubit.state.selection?.addressId, 'a2');
      expect(cubit.state.hasScheduledSlots, isFalse);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a pickup selection reads no windows', () async {
      final cubit = build();
      await cubit.start();

      await cubit.selectBranch('b1');

      expect(repository.calls, isNot(contains('slots')));
      await cubit.close();
    });

    test('a window the new address does not offer goes back to ASAP', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      cubit.setSlot(cubit.state.slotDays.single.slots.single);
      repository.days = const <DeliverySlotDayEntity>[
        DeliverySlotDayEntity(
          date: '2026-09-22',
          label: 'Tomorrow',
          slots: <DeliverySlotEntity>[
            DeliverySlotEntity(
              templateId: 't9',
              date: '2026-09-22',
              label: '18:00 – 20:00',
              remaining: 3,
              available: true,
            ),
          ],
        ),
      ];
      final notices = <CheckoutNotice>[];
      final sub = cubit.stream.listen((state) => notices.add(state.notice));

      await cubit.selectAddress('a2');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.draft.timing, DeliveryTiming.asap);
      expect(cubit.state.draft.slot, isNull);
      expect(notices, contains(CheckoutNotice.slotReset));
      // Transient: the next change clears it.
      cubit.setNotes('x');
      expect(cubit.state.notice, CheckoutNotice.none);
      await sub.cancel();
      await cubit.close();
    });

    test('a window the new address still offers stays booked', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      final slot = cubit.state.slotDays.single.slots.single;
      cubit.setSlot(slot);

      await cubit.selectAddress('a2');

      expect(cubit.state.draft.timing, DeliveryTiming.scheduled);
      expect(cubit.state.draft.slot, slot);
      expect(cubit.state.notice, CheckoutNotice.none);
      await cubit.close();
    });

    test('a booked window keeps the selection in flight until the new '
        "address's windows are read", () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      cubit.setSlot(cubit.state.slotDays.single.slots.single);
      final gate = Completer<void>();
      repository.slotsGate = gate;

      final selecting = cubit.selectAddress('a2');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // The new address is priced, but its windows are not checked yet.
      expect(cubit.state.selection?.addressId, 'a2');
      expect(cubit.state.isSelecting, isTrue);
      expect(cubit.state.canPlace, isFalse);
      await cubit.placeOrder(ready);
      expect(repository.calls, isNot(contains('place:cod')));

      gate.complete();
      await selecting;
      expect(cubit.state.isSelecting, isFalse);
      expect(cubit.state.canPlace, isTrue);
      await cubit.close();
    });

    test('without a booked window the selection is done at once', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      final gate = Completer<void>();
      repository.slotsGate = gate;

      final selecting = cubit.selectAddress('a2');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selection?.addressId, 'a2');
      expect(cubit.state.isSelecting, isFalse);
      gate.complete();
      await selecting;
      await cubit.close();
    });

    test('a booked window the failed read could not confirm goes back to '
        'ASAP, and says so', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      cubit.setSlot(cubit.state.slotDays.single.slots.single);
      repository.slotsFailure = const NetworkFailure();
      final notices = <CheckoutNotice>[];
      final sub = cubit.stream.listen((state) => notices.add(state.notice));

      await cubit.selectAddress('a2');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.draft.timing, DeliveryTiming.asap);
      expect(cubit.state.draft.slot, isNull);
      expect(cubit.state.hasScheduledSlots, isFalse);
      expect(notices, contains(CheckoutNotice.slotReset));
      expect(cubit.state.isSelecting, isFalse);
      await sub.cancel();
      await cubit.close();
    });
  });

  test('a 401 on the first load is the same sign-in signal', () async {
    final cubit = build();
    repository.branchesFailure = const UnauthorizedFailure();

    await cubit.start();

    expect(cubit.state.status, CheckoutStatus.error);
    expect(cubit.state.requiresSignIn, isTrue);
    await cubit.close();
  });

  group('placeOrder(facts) re-checks the block reasons', () {
    test('a cart still moving is not placed', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');

      await cubit.placeOrder(const CheckoutCartFacts(settled: false));

      expect(repository.calls, isNot(contains('place:cod')));
      await cubit.close();
    });

    test('a cart block is not placed', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');

      await cubit.placeOrder(
        const CheckoutCartFacts(block: CartCheckoutBlock.belowMinOrder),
      );
      await cubit.placeOrder(const CheckoutCartFacts(unsynced: true));

      expect(repository.calls, isNot(contains('place:cod')));
      await cubit.close();
    });

    test('a wallet that does not cover the total is not placed', () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');
      cubit.setPaymentMethod(OrderPaymentMethod.wallet);

      await cubit.placeOrder(
        const CheckoutCartFacts(walletFils: 1000, totalFils: 2600),
      );

      expect(repository.calls, isNot(contains('place:wallet')));
      await cubit.close();
    });

    test(
      'cash on delivery while the store turned it off is not placed',
      () async {
        final cubit = build();
        repository.rules = const CheckoutStoreRules(codEnabled: false);
        await cubit.start(defaultAddressId: 'a1');

        await cubit.placeOrder(ready);

        expect(repository.calls, isNot(contains('place:cod')));
        expect(reasonOf(cubit), CheckoutBlockReason.payment);
        await cubit.close();
      },
    );

    test('maintenance is not placed', () async {
      final cubit = build();
      repository.rules = const CheckoutStoreRules(maintenance: true);
      await cubit.start(defaultAddressId: 'a1');

      await cubit.placeOrder(ready);

      expect(repository.calls, isNot(contains('place:cod')));
      expect(reasonOf(cubit), CheckoutBlockReason.maintenance);
      await cubit.close();
    });
  });
}
