// Create / edit address form: seeding, validation, POST vs diff-only PATCH,
// the double-submit guard and transient failures.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/address_label.dart';
import 'package:jameia_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_draft.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_field.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_edit_cubit.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_edit_state.dart';

import 'address_test_fakes.dart';

void main() {
  late FakeAddAddressUseCase addAddress;
  late FakeUpdateAddressUseCase updateAddress;

  final created = address(n: 5);
  final existing = address(n: 1, floor: '2');

  AddressEditCubit build({bool edit = false, bool isFirstAddress = false}) =>
      AddressEditCubit(
        addAddress: addAddress,
        updateAddress: updateAddress,
        original: edit ? existing : null,
        isFirstAddress: isFirstAddress,
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
      expect(cubit.state.draft.location, AddressDraft.kuwaitCity);
    });

    test("a customer's first address starts as the default", () {
      final cubit = build(isFirstAddress: true);
      addTearDown(cubit.close);
      expect(cubit.state.draft.isDefault, isTrue);
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
          const GeoPointEntity(lat: 29.1, lng: 48.1),
          city: 'Fintas',
          street: 'Street 5',
        );
      final draft = cubit.state.draft;
      expect(draft.notes, 'Gate code 12');
      expect(draft.label, AddressLabel.work);
      expect(draft.isDefault, isTrue);
      expect(draft.location, const GeoPointEntity(lat: 29.1, lng: 48.1));
      expect(draft.city, 'Fintas');
      expect(draft.street, 'Street 5');
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
