import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/jameia_address_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/storage/local_storage.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_book.dart';
import 'package:jameia_mart/src/features/address/domain/entities/cached_address_book.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/add_address_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/clear_cached_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/delete_address_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/get_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/get_cached_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/save_cached_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/update_address_usecase.dart';

/// A 24-hex Mongo id ending in [n].
String addressId(int n) => n.toString().padLeft(24, 'a');

JameiaAddressEntity address({
  int n = 1,
  String label = 'Home',
  String city = 'Salmiya',
  String block = '7',
  String street = '22',
  String building = '5',
  String floor = '',
  String apartment = '',
  String phone = '+96550001122',
  String notes = '',
  GeoPointEntity? location = const GeoPointEntity(lat: 29.33, lng: 48.07),
  bool isDefault = false,
}) => JameiaAddressEntity(
  id: addressId(n),
  label: label,
  city: city,
  block: block,
  street: street,
  building: building,
  floor: floor,
  apartment: apartment,
  phone: phone,
  notes: notes,
  location: location,
  isDefault: isDefault,
);

/// An API row as `/v1/account/addresses` sends it.
Map<String, Object?> addressJson({
  int n = 1,
  String label = 'Home',
  bool isDefault = false,
}) => <String, Object?>{
  '_id': addressId(n),
  'label': label,
  'city': 'Salmiya',
  'block': '7',
  'street': '22',
  'building': '5',
  'phone': '+96550001122',
  'lat': 29.33,
  'lng': 48.07,
  'isDefault': isDefault,
};

/// `LocalStorage` over a map; [failWrites] makes every write report `false`.
class InMemoryLocalStorage implements LocalStorage {
  final Map<String, Object> values = {};
  bool failWrites = false;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<bool> setBool(String key, {required bool value}) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (failWrites) return false;
    values.remove(key);
    return true;
  }
}

/// Replies are held while [gate] is set (in-flight races).
mixin _Gated {
  Completer<void>? gate;

  Future<void> waitGate() async => gate?.future;
}

class FakeGetCachedAddressesUseCase
    with _Gated
    implements GetCachedAddressesUseCase {
  FakeGetCachedAddressesUseCase([
    this.result = const Right(CachedAddressBook.none),
  ]);

  Either<Failure, CachedAddressBook> result;
  int calls = 0;

  @override
  Future<Either<Failure, CachedAddressBook>> call(NoParams params) async {
    calls++;
    await waitGate();
    return result;
  }
}

class FakeGetAddressesUseCase with _Gated implements GetAddressesUseCase {
  FakeGetAddressesUseCase(this.result);

  Either<Failure, AddressBook> result;
  int calls = 0;

  /// Consumed first, one per call, before falling back to [result].
  final List<Either<Failure, AddressBook>> queue = [];

  @override
  Future<Either<Failure, AddressBook>> call(NoParams params) async {
    calls++;
    final reply = queue.isEmpty ? result : queue.removeAt(0);
    await waitGate();
    return reply;
  }
}

class FakeDeleteAddressUseCase with _Gated implements DeleteAddressUseCase {
  FakeDeleteAddressUseCase([this.result = const Right(unit)]);

  Either<Failure, Unit> result;
  final List<DeleteAddressParams> calls = [];

  @override
  Future<Either<Failure, Unit>> call(DeleteAddressParams params) async {
    calls.add(params);
    await waitGate();
    return result;
  }
}

class FakeSaveCachedAddressesUseCase implements SaveCachedAddressesUseCase {
  Either<Failure, Unit> result = const Right(unit);

  /// Every write, in order: the book and the owner it was saved for.
  final List<SaveCachedAddressesParams> writes = [];

  List<AddressBook> get saved => [for (final write in writes) write.book];

  @override
  Future<Either<Failure, Unit>> call(SaveCachedAddressesParams params) async {
    writes.add(params);
    return result;
  }
}

class FakeClearCachedAddressesUseCase implements ClearCachedAddressesUseCase {
  int calls = 0;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    calls++;
    return const Right(unit);
  }
}

class FakeAddAddressUseCase with _Gated implements AddAddressUseCase {
  FakeAddAddressUseCase(this.result);

  Either<Failure, JameiaAddressEntity> result;
  final List<AddAddressParams> calls = [];

  @override
  Future<Either<Failure, JameiaAddressEntity>> call(
    AddAddressParams params,
  ) async {
    calls.add(params);
    await waitGate();
    return result;
  }
}

class FakeUpdateAddressUseCase with _Gated implements UpdateAddressUseCase {
  FakeUpdateAddressUseCase(this.result);

  Either<Failure, JameiaAddressEntity> result;
  final List<UpdateAddressParams> calls = [];

  @override
  Future<Either<Failure, JameiaAddressEntity>> call(
    UpdateAddressParams params,
  ) async {
    calls.add(params);
    await waitGate();
    return result;
  }
}
