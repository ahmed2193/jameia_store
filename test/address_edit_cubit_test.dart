// Smoke test: AddressEditCubit create/edit flow.
//
// A fresh cubit (initial: null) is in CREATE mode (not editing). The discrete
// setters update state, save() composes a JameiaAddress and persists it through
// the AddressRepository (add on create, update on edit), and validate() flags
// missing required info appropriately.
//
// Post P2.9 refactor: the pass-through use cases were deleted and the cubit
// depends on the AddressRepository directly. This test drives it over a
// hand-written fake repository (the project's mocking convention — see
// `_FakeCheckoutRepo` in checkout_cubit_test.dart; the repo has no mocktail
// dependency) that records what it persists, so save() still exercises the
// end-to-end compose → persist → return-saved-row behavior.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jameia_mart/src/core/data/models/models.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/address/domain/entities/jameia_address_entity.dart';
import 'package:jameia_mart/src/features/address/domain/entities/region_options.dart';
import 'package:jameia_mart/src/features/address/domain/repositories/address_repository.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_edit_cubit.dart';

/// Configurable fake — records the address book and how many times each write
/// path was taken, echoing the persisted row back (or a [CacheFailure] when
/// [failWrites]) so save()'s success/failure branches are both reachable. Only
/// the add/update write paths are used by [AddressEditCubit]; the rest satisfy
/// the interface.
class _FakeAddressRepository implements AddressRepository {
  bool failWrites = false;

  final List<JameiaAddress> book = <JameiaAddress>[];
  int addCalls = 0;
  int updateCalls = 0;

  JameiaAddress _upsert(JameiaAddress a) {
    book.removeWhere((e) => e.id == a.id);
    book.add(a);
    return a;
  }

  @override
  Future<Either<Failure, JameiaAddress>> addAddress(
    JameiaAddress address,
  ) async {
    addCalls++;
    if (failWrites) return const Left(CacheFailure('add failed'));
    return Right(_upsert(address));
  }

  @override
  Future<Either<Failure, JameiaAddress>> updateAddress(
    JameiaAddress address,
  ) async {
    updateCalls++;
    if (failWrites) return const Left(CacheFailure('update failed'));
    return Right(_upsert(address));
  }

  // ── Unused by AddressEditCubit — satisfy the interface. ─────────────────────
  @override
  Future<Either<Failure, List<JameiaAddressEntity>>> getAddresses() async =>
      const Right(<JameiaAddressEntity>[]);

  @override
  Future<Either<Failure, Unit>> deleteAddress(String id) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> setPrimaryAddress(String id) async =>
      const Right(unit);

  @override
  Future<Either<Failure, RegionOptions>> getServiceRegions() async =>
      const Left(CacheFailure());

  @override
  Future<Either<Failure, Unit>> switchRegion(String region) async =>
      const Right(unit);
}

void main() {
  late _FakeAddressRepository repo;

  // Build the cubit over the fake repository (create mode by default).
  AddressEditCubit newCubit() => AddressEditCubit(repo);

  // Fill every `necessary` apartment field + recipient + a valid 8-digit phone.
  void fillValidApartment(AddressEditCubit cubit) {
    cubit.setField(AddrField.area, 'Salmiya');
    cubit.setField(AddrField.buildingName, 'Tower One');
    cubit.setField(AddrField.aptNumber, '1204');
    cubit.setField(AddrField.unitOrFloor, 'Floor 12');
    cubit.setField(AddrField.street, '22');
    cubit.setField(AddrField.block, '7');
    cubit.setField(AddrField.recipient, 'Ahmed');
    cubit.setField(AddrField.phone, '50001122');
  }

  setUp(() {
    repo = _FakeAddressRepository();
  });

  test('fresh cubit (initial: null) is not editing', () {
    final cubit = newCubit();
    expect(cubit.isEditing, isFalse);
    expect(cubit.state.id, isNull);
    addTearDown(cubit.close);
  });

  test('setLabel / setStructType / setDropOff update state', () {
    final cubit = newCubit();
    addTearDown(cubit.close);

    expect(cubit.state.label, LabelType.home);
    cubit.setLabel(LabelType.work);
    expect(cubit.state.label, LabelType.work);

    expect(cubit.state.structType, StructType.apartment);
    cubit.setStructType(StructType.office);
    expect(cubit.state.structType, StructType.office);

    expect(cubit.state.dropOff, DropOff.handToMe);
    cubit.setDropOff(DropOff.leaveAtSpot);
    expect(cubit.state.dropOff, DropOff.leaveAtSpot);
  });

  test('validate() flags incomplete required info, then ok once filled', () {
    final cubit = newCubit();
    addTearDown(cubit.close);

    // Fresh apartment state has empty required fields → infoIncomplete.
    expect(cubit.validate(), AddressValidation.infoIncomplete);

    // Fill all `necessary` apartment fields + phone.
    cubit.setField(AddrField.area, 'Salmiya');
    cubit.setField(AddrField.buildingName, 'Tower One');
    cubit.setField(AddrField.aptNumber, '1204');
    cubit.setField(AddrField.unitOrFloor, 'Floor 12');
    cubit.setField(AddrField.street, '22');
    cubit.setField(AddrField.block, '7');
    cubit.setField(AddrField.phone, '50001122');
    expect(cubit.validate(), AddressValidation.ok);

    // Leave-at-spot needs an alt location.
    cubit.setDropOff(DropOff.leaveAtSpot);
    expect(cubit.validate(), AddressValidation.altRequired);
    cubit.setAltLocation('Reception desk');
    expect(cubit.validate(), AddressValidation.ok);

    // A too-short phone is flagged as phoneInvalid.
    cubit.setField(AddrField.phone, '123');
    expect(cubit.validate(), AddressValidation.phoneInvalid);
  });

  test('fieldErrors() flags required fields + phone, clears when valid', () {
    final cubit = newCubit();
    addTearDown(cubit.close);

    // A blank new (apartment) cubit reports its necessary schema fields,
    // the recipient, and the (empty) phone.
    final blank = cubit.fieldErrors();
    expect(blank[AddrField.area], 'addr.field_required');
    expect(blank[AddrField.buildingName], 'addr.field_required');
    expect(blank[AddrField.aptNumber], 'addr.field_required');
    expect(blank[AddrField.unitOrFloor], 'addr.field_required');
    expect(blank[AddrField.street], 'addr.field_required');
    expect(blank[AddrField.block], 'addr.field_required');
    expect(blank[AddrField.recipient], 'addr.recipient_required');
    expect(blank[AddrField.phone], 'addr.field_required');
    expect(cubit.isValid, isFalse);

    // Fill every necessary field + recipient + a valid 8-digit phone → clears.
    cubit.setField(AddrField.area, 'Salmiya');
    cubit.setField(AddrField.buildingName, 'Tower One');
    cubit.setField(AddrField.aptNumber, '1204');
    cubit.setField(AddrField.unitOrFloor, 'Floor 12');
    cubit.setField(AddrField.street, '22');
    cubit.setField(AddrField.block, '7');
    cubit.setField(AddrField.recipient, 'Ahmed');
    cubit.setField(AddrField.phone, '50001122');
    expect(cubit.fieldErrors(), isEmpty);
    expect(cubit.isValid, isTrue);

    // A 5-digit phone yields the format error.
    cubit.setField(AddrField.phone, '50001');
    final shortPhone = cubit.fieldErrors();
    expect(shortPhone[AddrField.phone], 'addr.phone_format');
    expect(shortPhone.length, 1); // only the phone is invalid now.
    expect(cubit.isValid, isFalse);

    // Restore a valid phone; leave-at-spot without an alt is still not valid.
    cubit.setField(AddrField.phone, '50001122');
    cubit.setDropOff(DropOff.leaveAtSpot);
    expect(cubit.fieldErrors(), isEmpty); // alt is not an AddrField.
    expect(cubit.isValid, isFalse); // but isValid gates on the alt-location.
    cubit.setAltLocation('Reception desk');
    expect(cubit.isValid, isTrue);
  });

  test(
    'save() composes a JameiaAddress and adds it through the repository',
    () async {
      final cubit = newCubit();
      addTearDown(cubit.close);

      cubit.setLabel(LabelType.work);
      cubit.setStructType(StructType.apartment);
      fillValidApartment(cubit);

      final saved = await cubit.save();

      // The composed row carries the entered fields.
      expect(saved, isNotNull);
      expect(saved!.id, isNotEmpty);
      expect(saved.label, 'Work');
      expect(saved.labelType, LabelType.work);
      expect(saved.structType, StructType.apartment);
      expect(saved.area, 'Salmiya');
      expect(saved.block, '7');
      expect(saved.street, '22');
      expect(saved.recipient, 'Ahmed');
      expect(saved.phone, '50001122');
      expect(saved.brief, isNotEmpty);

      // Create mode routes through addAddress (not updateAddress) and the row was
      // upserted into the repository's book.
      expect(repo.addCalls, 1);
      expect(repo.updateCalls, 0);
      expect(repo.book.any((a) => a.id == saved.id), isTrue);

      // On success the form settles into the `saved` status.
      expect(cubit.state.status, AddressEditStatus.saved);
    },
  );

  test(
    'save() on a seeded address routes through updateAddress (edit mode)',
    () async {
      const existing = JameiaAddress(
        id: 'addr_existing_1',
        label: 'Home',
        line: 'Block 3, Street 9, Beach Tower',
        area: 'Mahboula',
        recipient: 'Sara',
        phone: '50009988',
        isDefault: false,
        lat: 29.1456,
        lng: 48.1278,
        structType: StructType.apartment,
        labelType: LabelType.home,
        buildingName: 'Beach Tower',
        aptNumber: '8',
        unitOrFloor: 'Floor 4',
        street: '9',
        block: '3',
      );

      final cubit = newCubit()..seed(existing);
      addTearDown(cubit.close);

      // Seeding an existing address puts the cubit in EDIT mode.
      expect(cubit.isEditing, isTrue);
      expect(cubit.state.id, existing.id);

      // Change a field and save.
      cubit.setField(AddrField.recipient, 'Sara Updated');
      final saved = await cubit.save();

      // Edit mode routes through updateAddress (not addAddress), preserving the id.
      expect(saved, isNotNull);
      expect(saved!.id, existing.id);
      expect(saved.recipient, 'Sara Updated');
      expect(repo.updateCalls, 1);
      expect(repo.addCalls, 0);
      expect(repo.book.any((a) => a.id == existing.id), isTrue);
      expect(cubit.state.status, AddressEditStatus.saved);
    },
  );

  test(
    'save() surfaces a repository failure (returns null, error status)',
    () async {
      repo.failWrites = true;
      final cubit = newCubit();
      addTearDown(cubit.close);

      cubit.setStructType(StructType.apartment);
      fillValidApartment(cubit);

      final saved = await cubit.save();

      // A persistence failure is surfaced, not swallowed: null result + error
      // state carrying the failure message (nothing landed in the book).
      expect(saved, isNull);
      expect(repo.addCalls, 1);
      expect(repo.book, isEmpty);
      expect(cubit.state.status, AddressEditStatus.error);
      expect(cubit.state.error, 'add failed');
    },
  );
}
