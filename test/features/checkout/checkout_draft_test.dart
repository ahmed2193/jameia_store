import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/features/checkout/data/mappers/checkout_mapper.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/delivery_slot_entity.dart';

void main() {
  const slot = DeliverySlotEntity(
    templateId: 't1',
    date: '2026-09-22',
    start: '10:00',
    end: '12:00',
    remaining: 3,
    available: true,
  );

  group('completeness', () {
    test('delivery needs an address', () {
      expect(const CheckoutDraft().isComplete, isFalse);
      expect(const CheckoutDraft(addressId: 'a1').isComplete, isTrue);
    });

    test('pickup needs a branch, not an address', () {
      const draft = CheckoutDraft(
        mode: FulfillmentMode.pickup,
        addressId: 'a1',
      );
      expect(draft.isComplete, isFalse);
      expect(draft.copyWith(branchId: 'b1').isComplete, isTrue);
    });

    test('a scheduled order needs a slot', () {
      const draft = CheckoutDraft(
        addressId: 'a1',
        timing: DeliveryTiming.scheduled,
      );
      expect(draft.needsSlot, isTrue);
      expect(draft.isComplete, isFalse);
      expect(draft.copyWith(slot: slot).isComplete, isTrue);
    });

    test('notes over the API limit block the order', () {
      final draft = CheckoutDraft(
        addressId: 'a1',
        notes: 'x' * (CheckoutDraft.maxNotesLength + 1),
      );
      expect(draft.notesTooLong, isTrue);
      expect(draft.isComplete, isFalse);
    });

    test('leaving the scheduled timing drops the slot', () {
      const draft = CheckoutDraft(
        addressId: 'a1',
        timing: DeliveryTiming.scheduled,
        slot: slot,
      );
      final asap = draft.copyWith(timing: DeliveryTiming.asap, clearSlot: true);
      expect(asap.slot, isNull);
    });
  });

  group('toBody', () {
    test('sends the payment method only when nothing else is set', () {
      const draft = CheckoutDraft(addressId: 'a1');

      expect(draft.toBody(), <String, dynamic>{'paymentMethod': 'cod'});
    });

    test('trims the notes and drops them when empty', () {
      expect(
        const CheckoutDraft(addressId: 'a1', notes: '   ').toBody(),
        isNot(contains('notes')),
      );
      expect(
        const CheckoutDraft(
          addressId: 'a1',
          notes: '  ring twice  ',
        ).toBody()['notes'],
        'ring twice',
      );
    });

    test('a scheduled order books the slot by template and date', () {
      const draft = CheckoutDraft(
        addressId: 'a1',
        timing: DeliveryTiming.scheduled,
        slot: slot,
        paymentMethod: OrderPaymentMethod.wallet,
      );

      final body = draft.toBody();

      expect(body['paymentMethod'], 'wallet');
      expect(body['deliverySlot'], <String, dynamic>{
        'templateId': 't1',
        'date': '2026-09-22',
      });
    });

    test('an ASAP order sends no slot even when one was picked', () {
      const draft = CheckoutDraft(addressId: 'a1', slot: slot);

      expect(draft.toBody(), isNot(contains('deliverySlot')));
    });
  });
  group('DeliverySlotDayEntity label', () {
    test('a named day keeps the name the server sent', () {
      const day = DeliverySlotDayEntity(date: '2026-09-21', label: 'Today');

      expect(day.hasNamedLabel, isTrue);
    });

    test('a day whose label is just the wire date is not a name', () {
      // The backend repeats yyyy-MM-dd for the days it has no name for;
      // showing that to a customer is showing them the wire format.
      const day = DeliverySlotDayEntity(
        date: '2026-09-22',
        label: '2026-09-22',
      );

      expect(day.hasNamedLabel, isFalse);
      expect(day.day, DateTime(2026, 9, 22));
    });

    test('no label at all is not a name either', () {
      const day = DeliverySlotDayEntity(date: '2026-09-23');

      expect(day.hasNamedLabel, isFalse);
    });
  });
}
