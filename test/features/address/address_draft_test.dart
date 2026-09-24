// Address form rules (AddressDraft) and the PATCH diff (AddressUpdate).
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/address_label.dart';
import 'package:jameia_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_draft.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_field.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_update.dart';

import 'address_test_fakes.dart';

void main() {
  const valid = AddressDraft(
    city: 'Salmiya',
    block: '7',
    street: '22',
    building: '5',
    phone: '50001122',
  );

  group('AddressDraft validation', () {
    test('a complete draft is valid', () {
      expect(valid.isValid, isTrue);
      for (final field in AddressField.values) {
        expect(valid.errorFor(field), isNull, reason: field.name);
      }
    });

    test('city, block, street, building and phone are required', () {
      const empty = AddressDraft();
      expect(empty.isValid, isFalse);
      for (final field in [
        AddressField.city,
        AddressField.block,
        AddressField.street,
        AddressField.building,
        AddressField.phone,
      ]) {
        expect(
          empty.errorFor(field),
          AddressFieldError.required,
          reason: field.name,
        );
      }
      for (final field in [
        AddressField.floor,
        AddressField.apartment,
        AddressField.notes,
      ]) {
        expect(empty.errorFor(field), isNull, reason: field.name);
      }
    });

    test('blank text counts as empty', () {
      expect(
        valid.copyWith(street: '   ').errorFor(AddressField.street),
        AddressFieldError.required,
      );
    });

    test('backend limits: block / building 32, floor / apartment 16, '
        'notes 256', () {
      expect(
        valid.copyWith(block: 'x' * 33).errorFor(AddressField.block),
        AddressFieldError.tooLong,
      );
      expect(
        valid.copyWith(block: 'x' * 32).errorFor(AddressField.block),
        isNull,
      );
      expect(
        valid.copyWith(building: 'x' * 33).errorFor(AddressField.building),
        AddressFieldError.tooLong,
      );
      expect(
        valid.copyWith(floor: 'x' * 17).errorFor(AddressField.floor),
        AddressFieldError.tooLong,
      );
      expect(
        valid.copyWith(apartment: 'x' * 17).errorFor(AddressField.apartment),
        AddressFieldError.tooLong,
      );
      expect(
        valid.copyWith(notes: 'x' * 257).errorFor(AddressField.notes),
        AddressFieldError.tooLong,
      );
      expect(valid.copyWith(notes: 'x' * 257).isValid, isFalse);
    });

    test('phone: 8 local digits, with or without +965 and spacing', () {
      expect(
        valid.copyWith(phone: '5000112').errorFor(AddressField.phone),
        AddressFieldError.invalidPhone,
      );
      expect(valid.copyWith(phone: '+965 5000 1122').isValid, isTrue);
      expect(valid.copyWith(phone: '96550001122').wirePhone, '+96550001122');
      expect(valid.copyWith(phone: '5000-1122').wirePhone, '+96550001122');
    });

    test('an out-of-range pin is invalid', () {
      expect(
        valid.copyWith(location: const GeoPointEntity(lat: 91, lng: 0)).isValid,
        isFalse,
      );
    });
  });

  group('AddressDraft seeding', () {
    test('fromAddress copies the saved values; phone becomes local digits', () {
      final saved = address(floor: '2', apartment: '12', isDefault: true);
      final draft = AddressDraft.fromAddress(saved);
      expect(draft.label, AddressLabel.home);
      expect(draft.city, 'Salmiya');
      expect(draft.floor, '2');
      expect(draft.apartment, '12');
      expect(draft.phone, '50001122');
      expect(draft.location, saved.location);
      expect(draft.isDefault, isTrue);
    });

    test('an address without a pin opens on Kuwait City', () {
      final draft = AddressDraft.fromAddress(address(location: null));
      expect(draft.location, AddressDraft.kuwaitCity);
    });

    test(
      'pinnedAt fills resolved parts, keeps typed ones, clamps to limits',
      () {
        const typed = AddressDraft(block: '9', street: 'My street');
        final pinned = typed.pinnedAt(
          const GeoPointEntity(lat: 29.1, lng: 48.1),
          city: ' Mahboula ',
          block: '',
          street: 'Street 3',
          building: 'B' * 40,
        );
        expect(pinned.location, const GeoPointEntity(lat: 29.1, lng: 48.1));
        expect(pinned.city, 'Mahboula');
        expect(pinned.block, '9'); // empty resolution keeps what was typed
        expect(pinned.street, 'Street 3');
        expect(pinned.building, 'B' * AddressDraft.maxBuildingLength);
      },
    );
  });

  group('AddressUpdate.diff', () {
    final original = address(floor: '2', notes: 'Ring');

    test('an untouched form is empty', () {
      final update = AddressUpdate.diff(
        original: original,
        draft: AddressDraft.fromAddress(original),
      );
      expect(update.isEmpty, isTrue);
    });

    test('only changed, trimmed fields; clearing floor sends ""', () {
      final draft = AddressDraft.fromAddress(original)
          .copyWith(street: ' 23 ', floor: '', isDefault: true);
      final update = AddressUpdate.diff(original: original, draft: draft);
      expect(update.street, '23');
      expect(update.floor, '');
      expect(update.isDefault, isTrue);
      expect(update.city, isNull);
      expect(update.phone, isNull);
      expect(update.label, isNull);
      expect(update.location, isNull);
    });

    test('same phone in another format is not a change', () {
      final saved = address(phone: '50001122');
      final draft = AddressDraft.fromAddress(saved)
          .copyWith(phone: '+965 5000 1122');
      expect(AddressUpdate.diff(original: saved, draft: draft).phone, isNull);
    });

    test('a new phone is sent in wire form', () {
      final draft = AddressDraft.fromAddress(original)
          .copyWith(phone: '66001122');
      expect(
        AddressUpdate.diff(original: original, draft: draft).phone,
        '+96566001122',
      );
    });

    test('a custom label is kept unless another tag is picked', () {
      final custom = address(label: "Mom's house");
      final same = AddressDraft.fromAddress(custom);
      expect(same.label, AddressLabel.other);
      expect(AddressUpdate.diff(original: custom, draft: same).label, isNull);
      expect(
        AddressUpdate.diff(
          original: custom,
          draft: same.copyWith(label: AddressLabel.work),
        ).label,
        AddressLabel.work,
      );
    });

    test('a moved pin is a change; an unpinned address left on the fallback '
        'is not', () {
      final moved = AddressDraft.fromAddress(original)
          .copyWith(location: const GeoPointEntity(lat: 29.4, lng: 48.0));
      expect(
        AddressUpdate.diff(original: original, draft: moved).location,
        const GeoPointEntity(lat: 29.4, lng: 48.0),
      );
      final unpinned = address(location: null);
      expect(
        AddressUpdate.diff(
          original: unpinned,
          draft: AddressDraft.fromAddress(unpinned),
        ).isEmpty,
        isTrue,
      );
    });
  });
}
