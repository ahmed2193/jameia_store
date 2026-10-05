// Address form rules (AddressDraft) and the PATCH diff (AddressUpdate).
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/address_label.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_draft.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_field.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_parts.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_update.dart';
import 'package:hero_mart/src/features/address/domain/entities/building_type.dart';
import 'package:hero_mart/src/features/address/domain/entities/new_address_seed.dart';

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

    test('a new address takes the account number when it is a Kuwait '
        'mobile, and starts empty otherwise', () {
      expect(
        AddressDraft.seeded(
          const NewAddressSeed(isDefault: true, customerPhone: '+96599887766'),
        ),
        const AddressDraft(isDefault: true, phone: '99887766'),
      );
      expect(
        AddressDraft.seeded(
          const NewAddressSeed(customerPhone: '+201001234567'),
        ).phone,
        isEmpty,
      );
      expect(AddressDraft.seeded(const NewAddressSeed()).phone, isEmpty);
    });

    test('an address without a pin opens on Kuwait City', () {
      final draft = AddressDraft.fromAddress(address(location: null));
      expect(draft.location, GeoPointEntity.kuwaitCity);
    });

    test('a pin moved to another place takes all its address from the map '
        'there: a part it could not read is cleared, the customer\'s own '
        'details stay', () {
      const before = AddressDraft(
        location: GeoPointEntity(lat: 29.33, lng: 48.07),
        hasPin: true,
        city: 'Salmiya',
        block: '7',
        street: 'Gulf Road',
        building: '12',
        floor: '3',
        apartment: '8',
        notes: 'Blue gate',
        phone: '99887766',
      );
      const farwaniya = GeoPointEntity(lat: 29.27, lng: 47.95);
      final moved = before.pinnedAt(
        farwaniya,
        parts: const AddressParts(city: 'Farwaniya', street: 'Street 9'),
      );
      expect(moved.location, farwaniya);
      expect(moved.city, 'Farwaniya');
      expect(moved.street, 'Street 9'); // typed before: the map's now
      expect(moved.block, ''); // not read there: the old block is gone
      expect(moved.building, '');
      expect(moved.floor, '3');
      expect(moved.apartment, '8');
      expect(moved.notes, 'Blue gate');
      expect(moved.phone, '99887766');
    });

    test('a pin nudged on the same building keeps a part the map could not '
        'read there, and takes the ones it read', () {
      const before = AddressDraft(
        location: GeoPointEntity(lat: 29.33, lng: 48.07),
        hasPin: true,
        city: 'Salmiya',
        block: '7',
        street: 'Street 22',
        building: '12',
      );
      // About 11 m north.
      const nudged = GeoPointEntity(lat: 29.3301, lng: 48.07);
      final pinned = before.pinnedAt(
        nudged,
        parts: const AddressParts(city: 'Salmiya', street: 'Street 23'),
      );
      expect(pinned.street, 'Street 23');
      expect(pinned.block, '7');
      expect(pinned.building, '12');
    });

    test('the first pin of an address saved without one fills only what '
        'the form lacks: the saved details describe that address', () {
      final pinless = AddressDraft.fromAddress(
        address(street: '11', building: '', location: null),
      );
      expect(pinless.hasPin, isFalse);
      const there = GeoPointEntity(lat: 29.3375, lng: 47.6581);
      final pinned = pinless.pinnedAt(
        there,
        parts: const AddressParts(
          city: 'Jahra',
          street: 'Street 5',
          building: '40',
        ),
      );
      expect(pinned.hasPin, isTrue);
      expect(pinned.location, there);
      expect(pinned.city, pinless.city); // saved: kept
      expect(pinned.street, '11'); // saved: kept
      expect(pinned.building, '40'); // missing: filled from the map
    });

    test('a read that came late fills only the parts still empty', () {
      const draft = AddressDraft(
        location: GeoPointEntity(lat: 29.33, lng: 48.07),
        hasPin: true,
        city: 'Salmiya',
      );
      final filled = draft.filledFrom(
        const AddressParts(city: 'Jabriya', block: '4', street: 'Street 2'),
      );
      expect(filled.city, 'Salmiya');
      expect(filled.block, '4');
      expect(filled.street, 'Street 2');
      expect(filled.location, draft.location);
    });

    test('the map\'s parts are trimmed and cut to their limits', () {
      final pinned = const AddressDraft().pinnedAt(
        const GeoPointEntity(lat: 29.31, lng: 48.02),
        parts: AddressParts(
          city: '  Jabriya ',
          block: '1' * 40,
          building: 'B' * 40,
        ),
      );
      expect(pinned.city, 'Jabriya');
      expect(pinned.block.length, AddressDraft.maxBlockLength);
      expect(pinned.building, 'B' * AddressDraft.maxBuildingLength);
    });

    test('a house drops the floor and the flat; other types keep them', () {
      final flat = valid.copyWith(floor: '3', apartment: '12');
      final house = flat.withBuildingType(BuildingType.house);
      expect(house.buildingType, BuildingType.house);
      expect(house.floor, isEmpty);
      expect(house.apartment, isEmpty);
      final office = flat.withBuildingType(BuildingType.office);
      expect(office.floor, '3');
      expect(office.apartment, '12');
    });

    test('pinnedPlace is the pin as the form holds it', () {
      const at = GeoPointEntity(lat: 29.3, lng: 48.0);
      final place = valid.copyWith(location: at, city: ' Salmiya ').pinnedPlace;
      expect(place.location, at);
      expect(place.area, 'Salmiya');
      expect(place.block, '7');
      expect(place.street, '22');
      expect(place.building, '5');
      expect(place.name, isEmpty);
    });

    test('an edited address reads its building type from what it stores', () {
      expect(
        AddressDraft.fromAddress(address()).buildingType,
        BuildingType.house,
      );
      expect(
        AddressDraft.fromAddress(address(floor: '2')).buildingType,
        BuildingType.apartment,
      );
      expect(
        AddressDraft.fromAddress(address(label: 'Work', apartment: '14'))
            .buildingType,
        BuildingType.office,
      );
    });
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
