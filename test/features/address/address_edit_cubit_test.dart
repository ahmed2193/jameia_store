// Create / edit address form: seeding, validation, POST vs diff-only PATCH,
// the double-submit guard and transient failures.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/address_label.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_draft.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_field.dart';
import 'package:hero_mart/src/features/address/domain/entities/building_type.dart';
import 'package:hero_mart/src/features/address/domain/entities/new_address_seed.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_edit_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_edit_state.dart';

import 'address_test_fakes.dart';

void main() {
  late FakeAddAddressUseCase addAddress;
  late FakeUpdateAddressUseCase updateAddress;

  final created = address(n: 5);
  final existing = address(n: 1, floor: '2');

  AddressEditCubit build({
    bool edit = false,
    NewAddressSeed seed = const NewAddressSeed(),
  }) => AddressEditCubit(
    addAddress: addAddress,
    updateAddress: updateAddress,
    original: edit ? existing : null,
    seed: seed,
  );

  void fillValid(AddressEditCubit cubit) {
    cubit
      ..fieldChanged(AddressField.city, 'Salmiya')
      ..fieldChanged(AddressField.block, '7')
      ..fieldChanged(AddressField.street, '22')
      ..fieldChanged(AddressField.building, '5')
      ..fieldChanged(AddressField.phone, '50001122');
  }

  setUp(() {
    addAddress = FakeAddAddressUseCase(Right(created));
    updateAddress = FakeUpdateAddressUseCase(Right(existing));
  });

  group('seeding', () {
    test('create mode: empty draft at Kuwait City, not default', () {
      final cubit = build();
      addTearDown(cubit.close);
      expect(cubit.state.isEditing, isFalse);
      expect(cubit.state.draft, const AddressDraft());
      expect(cubit.state.draft.location, GeoPointEntity.kuwaitCity);
    });

    test("a customer's first address starts as the default", () {
      final cubit = build(seed: const NewAddressSeed(isDefault: true));
      addTearDown(cubit.close);
      expect(cubit.state.draft.isDefault, isTrue);
    });

    test("a new address starts with the customer's own number", () {
      final cubit = build(
        seed: const NewAddressSeed(customerPhone: '+96599887766'),
      );
      addTearDown(cubit.close);
      expect(cubit.state.draft.phone, '99887766');
      expect(cubit.state.errorFor(AddressField.phone), isNull);
    });

    test('an edited address keeps its own number, not the account one', () {
      final cubit = AddressEditCubit(
        addAddress: addAddress,
        updateAddress: updateAddress,
        original: existing,
        seed: const NewAddressSeed(customerPhone: '+96599887766'),
      );
      addTearDown(cubit.close);
      expect(cubit.state.draft.phone, '50001122');
    });

    test('edit mode: the draft holds the saved values', () {
      final cubit = build(edit: true);
      addTearDown(cubit.close);
      expect(cubit.state.isEditing, isTrue);
      expect(cubit.state.draft, AddressDraft.fromAddress(existing));
    });
  });

  group('editing', () {
    test('field, label, default and pin changes update the draft', () {
      final cubit = build();
      addTearDown(cubit.close);
      cubit
        ..fieldChanged(AddressField.notes, 'Gate code 12')
        ..labelChanged(AddressLabel.work)
        ..defaultChanged(true)
        ..pinConfirmed(
          const PinnedPlace(
            location: GeoPointEntity(lat: 29.1, lng: 48.1),
            area: 'Fintas',
            street: 'Street 5',
          ),
        );
      final draft = cubit.state.draft;
      expect(draft.notes, 'Gate code 12');
      expect(draft.label, AddressLabel.work);
      expect(draft.isDefault, isTrue);
      expect(draft.location, const GeoPointEntity(lat: 29.1, lng: 48.1));
      expect(draft.city, 'Fintas');
      expect(draft.street, 'Street 5');
    });

    test('a pin moved to another place rewrites the address from the map, '
        'typed words included', () {
      final cubit = build();
      addTearDown(cubit.close);
      cubit
        ..pinConfirmed(
          const PinnedPlace(
            location: GeoPointEntity(lat: 29.33, lng: 48.07),
            area: 'Salmiya',
            block: '7',
            street: 'Street 22',
          ),
        )
        ..fieldChanged(AddressField.street, 'Gulf Road')
        ..pinConfirmed(
          const PinnedPlace(
            location: GeoPointEntity(lat: 29.27, lng: 47.95),
            area: 'Farwaniya',
            block: '3',
            street: 'Street 9',
          ),
        );
      final draft = cubit.state.draft;
      expect(draft.location, const GeoPointEntity(lat: 29.27, lng: 47.95));
      expect(draft.city, 'Farwaniya');
      expect(draft.block, '3');
      expect(draft.street, 'Street 9');
    });

    test('an edited address follows its moved pin: its area, block, street '
        'and building become what the map read there; its own details '
        'stay', () {
      final cubit = build(edit: true);
      addTearDown(cubit.close);
      cubit.pinConfirmed(
        const PinnedPlace(
          location: GeoPointEntity(lat: 29.2, lng: 48.0),
          area: 'Somewhere else',
          street: 'Other street',
        ),
      );
      final draft = cubit.state.draft;
      expect(draft.location, const GeoPointEntity(lat: 29.2, lng: 48.0));
      expect(draft.city, 'Somewhere else');
      expect(draft.street, 'Other street');
      expect(draft.block, isEmpty);
      expect(draft.building, isEmpty);
      expect(draft.floor, existing.floor);
      expect(draft.phone, isNotEmpty);
    });

    test('a read of the confirmed pin that came after Confirm stopped '
        'waiting fills what is still empty; a read of another spot, or of '
        'an address with no pin yet, does nothing', () {
      final cubit = build();
      addTearDown(cubit.close);
      const spot = GeoPointEntity(lat: 29.33, lng: 48.07);
      cubit.pinReadLate(const PinnedPlace(location: spot, area: 'Salmiya'));
      expect(cubit.state.draft.city, isEmpty); // no pin confirmed yet

      cubit.pinConfirmed(const PinnedPlace(location: spot)); // timed out
      cubit.fieldChanged(AddressField.street, 'My street');
      cubit.pinReadLate(
        const PinnedPlace(
          location: GeoPointEntity(lat: 29.2, lng: 48.0),
          area: 'Elsewhere',
        ),
      );
      expect(cubit.state.draft.city, isEmpty);

      cubit.pinReadLate(
        const PinnedPlace(
          location: spot,
          area: 'Salmiya',
          block: '7',
          street: 'Street 9',
        ),
      );
      final draft = cubit.state.draft;
      expect(draft.city, 'Salmiya');
      expect(draft.block, '7');
      expect(draft.street, 'My street'); // typed meanwhile: kept
    });

    test('a house drops the floor and the flat it no longer asks for', () {
      final cubit = build(edit: true);
      addTearDown(cubit.close);
      expect(cubit.state.draft.buildingType, BuildingType.apartment);
      cubit.buildingTypeChanged(BuildingType.house);
      expect(cubit.state.draft.buildingType, BuildingType.house);
      expect(cubit.state.draft.floor, isEmpty);
    });

    test('inline errors appear only after a rejected submit', () async {
      final cubit = build();
      addTearDown(cubit.close);
      expect(cubit.state.errorFor(AddressField.city), isNull);

      await cubit.save();
      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.rejected, isTrue);
      expect(
        cubit.state.errorFor(AddressField.city),
        AddressFieldError.required,
      );
      expect(addAddress.calls, isEmpty);

      // Typing a value clears that field's error; `rejected` was one-shot.
      cubit.fieldChanged(AddressField.city, 'Salmiya');
      expect(cubit.state.errorFor(AddressField.city), isNull);
      expect(cubit.state.rejected, isFalse);
    });
  });

  group('create', () {
    test(
      'a valid draft POSTs once and ends saved with the server copy',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        fillValid(cubit);
        await cubit.save();
        expect(addAddress.calls.single.draft, cubit.state.draft);
        expect(cubit.state.status, AddressEditStatus.saved);
        expect(cubit.state.saved, created);
      },
    );

    test('a double tap sends one request', () async {
      final cubit = build();
      addTearDown(cubit.close);
      fillValid(cubit);
      addAddress.gate = Completer<void>();
      final first = cubit.save();
      final second = cubit.save();
      expect(cubit.state.isSaving, isTrue);
      addAddress.gate!.complete();
      await Future.wait([first, second]);
      expect(addAddress.calls, hasLength(1));
    });

    test('a failure returns to editing with a transient failure', () async {
      addAddress.result = const Left(
        ServerFailure(
          'Validation failed',
          statusCode: 400,
          code: 'VALIDATION_ERROR',
        ),
      );
      final cubit = build();
      addTearDown(cubit.close);
      fillValid(cubit);
      await cubit.save();
      expect(cubit.state.status, AddressEditStatus.editing);
      expect(cubit.state.failure, isA<ServerFailure>());

      cubit.fieldChanged(AddressField.notes, 'x');
      expect(cubit.state.failure, isNull);
    });
  });

  group('edit', () {
    test('an unchanged form is saved without a request', () async {
      final cubit = build(edit: true);
      addTearDown(cubit.close);
      await cubit.save();
      expect(updateAddress.calls, isEmpty);
      expect(cubit.state.status, AddressEditStatus.saved);
      expect(cubit.state.saved, existing);
    });

    test('only the changed fields are PATCHed', () async {
      final updated = address(n: 1, floor: '');
      updateAddress.result = Right(updated);
      final cubit = build(edit: true);
      addTearDown(cubit.close);
      cubit.fieldChanged(AddressField.floor, '');
      await cubit.save();

      final call = updateAddress.calls.single;
      expect(call.id, existing.id);
      expect(call.update.floor, '');
      expect(call.update.city, isNull);
      expect(call.update.phone, isNull);
      expect(cubit.state.saved, updated);
    });

    test('an edited address must still be valid', () async {
      final cubit = build(edit: true);
      addTearDown(cubit.close);
      cubit.fieldChanged(AddressField.street, '');
      await cubit.save();
      expect(updateAddress.calls, isEmpty);
      expect(cubit.state.rejected, isTrue);
    });
  });
}
