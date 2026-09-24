// Address DTO (`/v1/account/addresses` rows), the entity mappers and the
// POST / PATCH body mappers.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/address_label.dart';
import 'package:jameia_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/features/address/data/mappers/address_body_mapper.dart';
import 'package:jameia_mart/src/features/address/data/mappers/address_mapper.dart';
import 'package:jameia_mart/src/features/address/data/models/address_model.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_draft.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_update.dart';

import 'address_test_fakes.dart';

void main() {
  // Every field the spec lists for an address row.
  final fullRow = <String, dynamic>{
    '_id': addressId(1),
    'label': 'Home',
    'city': 'Salmiya',
    'governorateNo': '3',
    'areaId': '120',
    'block': '7',
    'street': '22',
    'building': '5',
    'floor': '2',
    'apartment': '12',
    'phone': '+96550001122',
    'notes': 'Ring twice',
    'lat': 29.33,
    'lng': 48.07,
    'isDefault': true,
  };

  group('AddressModel.fromJson', () {
    test('full row → entity, field by field', () {
      final entity = AddressModel.fromJson(fullRow).toEntity();
      expect(entity.id, addressId(1));
      expect(entity.label, 'Home');
      expect(entity.labelKind, AddressLabel.home);
      expect(entity.city, 'Salmiya');
      expect(entity.governorateNo, '3');
      expect(entity.areaId, '120');
      expect(entity.block, '7');
      expect(entity.street, '22');
      expect(entity.building, '5');
      expect(entity.floor, '2');
      expect(entity.apartment, '12');
      expect(entity.phone, '+96550001122');
      expect(entity.notes, 'Ring twice');
      expect(entity.location, const GeoPointEntity(lat: 29.33, lng: 48.07));
      expect(entity.isDefault, isTrue);
    });

    test('minimal row (required keys only) falls back to empty values', () {
      final entity = AddressModel.fromJson({
        '_id': addressId(2),
        'label': 'Work',
        'isDefault': false,
      }).toEntity();
      expect(entity.city, isEmpty);
      expect(entity.block, isEmpty);
      expect(entity.phone, isEmpty);
      expect(entity.location, isNull);
      expect(entity.isDefault, isFalse);
    });

    test('tolerates `id`, numbers as text and coordinates as strings', () {
      final model = AddressModel.fromJson({
        'id': addressId(3),
        'label': 'Home',
        'block': 7,
        'lat': '29.5',
        'lng': 48,
      });
      expect(model.id, addressId(3));
      expect(model.block, '7');
      expect(model.lat, 29.5);
      expect(model.lng, 48.0);
    });

    test('only one coordinate → no pin', () {
      final entity = AddressModel.fromJson({
        '_id': addressId(4),
        'label': 'Home',
        'lat': 29.3,
      }).toEntity();
      expect(entity.location, isNull);
    });

    test('a missing id throws ParsingException', () {
      expect(
        () => AddressModel.fromJson({'label': 'Home'}),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => AddressModel.fromJson({'_id': '', 'label': 'Home'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('an id that is not an ObjectId throws (it would go into a path)', () {
      for (final bad in ['..', 'a/b', 'abc', '${addressId(1)}x', 42]) {
        expect(
          () => AddressModel.fromJson({'_id': bad, 'label': 'Home'}),
          throwsA(isA<ParsingException>()),
          reason: '$bad',
        );
      }
      expect(AddressModel.isObjectId('507F1F77BCF86CD799439011'), isTrue);
    });

    test('listFromJson skips malformed rows and keeps the rest', () {
      final models = AddressModel.listFromJson([
        addressJson(n: 1),
        {'label': 'no id'},
        {'_id': '..', 'label': 'bad id'},
        'not a map',
        null,
        addressJson(n: 2),
      ]);
      expect(models.map((m) => m.id), [addressId(1), addressId(2)]);
    });
  });

  group('cache round trip', () {
    test(
      'toJson writes the API keys back; entity → model → entity is lossless',
      () {
        final model = AddressModel.fromJson(fullRow);
        expect(model.toJson(), fullRow);
        final entity = model.toEntity();
        final back = AddressModel.fromJson(entity.toModel().toJson())
            .toEntity();
        expect(back, entity);
      },
    );

    test('empty optional fields and a missing pin are omitted', () {
      final json = address(location: null).toModel().toJson();
      expect(json.containsKey('floor'), isFalse);
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('lat'), isFalse);
      expect(json.containsKey('lng'), isFalse);
      expect(json['isDefault'], isFalse);
    });
  });

  group('AddressDraft.toBody (POST)', () {
    test('required keys always, optional ones only when filled', () {
      const draft = AddressDraft(
        location: GeoPointEntity(lat: 29.1, lng: 48.2),
        label: AddressLabel.work,
        city: '  Hawally ',
        block: '4',
        street: '',
        building: ' 12 ',
        floor: '',
        apartment: '3',
        phone: '5000 1122',
        notes: '  ',
        isDefault: true,
      );
      expect(draft.toBody(), {
        'label': 'Work',
        'lat': 29.1,
        'lng': 48.2,
        'city': 'Hawally',
        'block': '4',
        'building': '12',
        'apartment': '3',
        'phone': '+96550001122',
        'isDefault': true,
      });
    });
  });

  group('AddressUpdate.toBody (PATCH)', () {
    test('an empty update has an empty body', () {
      expect(const AddressUpdate().toBody(), isEmpty);
    });

    test('only the changed keys; a moved pin sends lat + lng; "" clears', () {
      const update = AddressUpdate(
        label: AddressLabel.gathering,
        location: GeoPointEntity(lat: 29.2, lng: 48.1),
        floor: '',
        isDefault: false,
      );
      expect(update.toBody(), {
        'label': 'Gathering',
        'lat': 29.2,
        'lng': 48.1,
        'floor': '',
        'isDefault': false,
      });
    });
  });
}
