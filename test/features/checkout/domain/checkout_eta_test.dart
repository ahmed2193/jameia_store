import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/delivery_slot_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_eta.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/delivery_selection_entity.dart';

void main() {
  const selection = DeliverySelectionEntity(
    mode: FulfillmentMode.delivery,
    branchId: 'b1',
    etaMinutes: 40,
  );
  const slot = DeliverySlotEntity(
    templateId: 't1',
    date: '2026-09-22',
    label: '10:00 – 12:00',
    remaining: 2,
    available: true,
  );

  CheckoutEta eta({
    CheckoutDraft draft = const CheckoutDraft(addressId: 'a1'),
    DeliverySelectionEntity? selection = selection,
    bool expressSelected = false,
    int? expressEtaMinutes,
    int? cartEtaMinutes,
    bool branchOpen = true,
    bool capacityAvailable = true,
  }) => CheckoutEta.of(
    draft: draft,
    selection: selection,
    expressSelected: expressSelected,
    expressEtaMinutes: expressEtaMinutes,
    cartEtaMinutes: cartEtaMinutes,
    branchOpen: branchOpen,
    capacityAvailable: capacityAvailable,
  );

  test('no selection yet: unknown', () {
    final value = eta(selection: null);

    expect(value.kind, CheckoutEtaKind.unknown);
    expect(value.showsCard, isFalse);
  });

  test('ASAP uses the cart estimate, else the selection one', () {
    expect(eta(cartEtaMinutes: 45).minutes, 45);
    final fallback = eta();
    expect(fallback.kind, CheckoutEtaKind.asap);
    expect(fallback.minutes, 40);
    expect(fallback.showsCard, isTrue);
  });

  test('pickup: the branch estimate, no card', () {
    final value = eta(
      draft: const CheckoutDraft(mode: FulfillmentMode.pickup, branchId: 'b1'),
      selection: const DeliverySelectionEntity(
        mode: FulfillmentMode.pickup,
        branchId: 'b1',
        etaMinutes: 30,
      ),
    );

    expect(value.kind, CheckoutEtaKind.pickup);
    expect(value.minutes, 30);
    expect(value.showsCard, isFalse);
    expect(value.arrivesAround(DateTime(2026, 9, 26, 10)), isNull);
  });

  test('pickup at a closed or full branch says so, not "ready in N min"', () {
    const pickup = CheckoutDraft(mode: FulfillmentMode.pickup, branchId: 'b1');
    const branch = DeliverySelectionEntity(
      mode: FulfillmentMode.pickup,
      branchId: 'b1',
      etaMinutes: 30,
    );

    final closed = eta(draft: pickup, selection: branch, branchOpen: false);
    expect(closed.kind, CheckoutEtaKind.branchClosed);
    expect(closed.minutes, isNull);
    expect(closed.showsCard, isFalse);

    expect(
      eta(draft: pickup, selection: branch, capacityAvailable: false).kind,
      CheckoutEtaKind.noCapacity,
    );
  });

  test('express: the express minutes; the bolt only when really faster', () {
    const express = CheckoutDraft(
      addressId: 'a1',
      timing: DeliveryTiming.express,
    );

    final slower = eta(
      draft: express,
      expressSelected: true,
      expressEtaMinutes: 60,
      cartEtaMinutes: 60,
    );
    expect(slower.kind, CheckoutEtaKind.express);
    expect(slower.minutes, 60);
    expect(slower.expressFaster, isFalse);

    final faster = eta(
      draft: express,
      expressSelected: true,
      expressEtaMinutes: 15,
    );
    expect(faster.minutes, 15);
    expect(faster.expressFaster, isTrue);

    // The draft says express but the cart did not take it: ASAP.
    expect(eta(draft: express).kind, CheckoutEtaKind.asap);
  });

  test('a booked window: scheduled, no clock time', () {
    final value = eta(
      draft: const CheckoutDraft(
        addressId: 'a1',
        timing: DeliveryTiming.scheduled,
        slot: slot,
      ),
    );

    expect(value.kind, CheckoutEtaKind.scheduled);
    expect(value.slot, slot);
    expect(value.showsCard, isTrue);
    expect(value.arrivesAround(DateTime(2026, 9, 26, 10)), isNull);
  });

  test('a closed branch or no capacity: that state, no card', () {
    final closed = eta(branchOpen: false, cartEtaMinutes: 45);
    expect(closed.kind, CheckoutEtaKind.branchClosed);
    expect(closed.showsCard, isFalse);

    expect(eta(capacityAvailable: false).kind, CheckoutEtaKind.noCapacity);
  });

  test('arrivesAround rounds up to the next 5 minutes', () {
    final value = eta(cartEtaMinutes: 45);

    expect(
      value.arrivesAround(DateTime(2026, 9, 26, 10, 3)),
      DateTime(2026, 9, 26, 10, 50),
    );
    expect(
      value.arrivesAround(DateTime(2026, 9, 26, 10, 5)),
      DateTime(2026, 9, 26, 10, 50),
    );
    expect(
      value.arrivesAround(DateTime(2026, 9, 26, 10, 6)),
      DateTime(2026, 9, 26, 10, 55),
    );
    // Seconds are dropped before rounding.
    expect(
      value.arrivesAround(DateTime(2026, 9, 26, 10, 5, 42)),
      DateTime(2026, 9, 26, 10, 50),
    );
  });

  test('no estimate: no clock time', () {
    const none = CheckoutEta(kind: CheckoutEtaKind.asap);

    expect(none.arrivesAround(DateTime(2026, 9, 26, 10)), isNull);
    expect(none.showsCard, isFalse);
  });
}
