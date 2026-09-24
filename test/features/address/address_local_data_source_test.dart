// The device copy of the address book: the owner + the API rows as JSON under
// one key; clearing it also removes the retired copies.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/features/address/data/datasources/address_local_data_source.dart';
import 'package:jameia_mart/src/features/address/data/models/address_model.dart';
import 'package:jameia_mart/src/features/address/data/models/cached_address_book_model.dart';

import 'address_test_fakes.dart';

void main() {
  late InMemoryLocalStorage storage;
  late AddressLocalDataSourceImpl dataSource;

  const owner = 'aaaaaaaaaaaaaaaaaaaaaaaa';

  setUp(() {
    storage = InMemoryLocalStorage();
    dataSource = AddressLocalDataSourceImpl(storage);
  });

  test('nothing cached → the empty copy', () async {
    final copy = await dataSource.readAddresses();
    expect(copy.ownerId, isNull);
    expect(copy.addresses, isEmpty);
  });

  test('save stores the owner + the API rows; read returns them', () async {
    await dataSource.saveAddresses(
      CachedAddressBookModel(
        ownerId: owner,
        addresses: [
          AddressModel.fromJson(addressJson(n: 1, isDefault: true)),
          AddressModel.fromJson(addressJson(n: 2)),
        ],
      ),
    );

    final stored = jsonDecode(
      storage.values[AddressLocalDataSourceImpl.cacheKey]! as String,
    );
    expect(stored, {
      'ownerId': owner,
      'addresses': [addressJson(n: 1, isDefault: true), addressJson(n: 2)],
    });

    final read = await dataSource.readAddresses();
    expect(read.ownerId, owner);
    expect(read.addresses.map((m) => m.toJson()), stored['addresses']);
  });

  test(
    'a copy saved without a known customer reads back with no owner',
    () async {
      await dataSource.saveAddresses(
        CachedAddressBookModel(
          addresses: [AddressModel.fromJson(addressJson())],
        ),
      );
      final read = await dataSource.readAddresses();
      expect(read.ownerId, isNull);
      expect(read.addresses, hasLength(1));
    },
  );

  test('clear removes the copy and the retired address books', () async {
    storage.values
      ..['account.addresses.v1'] = '[]'
      ..['jameia.addressbook.v1'] = '[{"id":"legacy"}]'
      ..['app_language'] = 'ar';
    await dataSource.saveAddresses(CachedAddressBookModel.empty);

    await dataSource.clear();

    expect(storage.values.keys, ['app_language']);
    expect((await dataSource.readAddresses()).addresses, isEmpty);
  });

  test('an unreadable copy throws CacheException', () async {
    storage.values[AddressLocalDataSourceImpl.cacheKey] = '{not json';
    await expectLater(
      dataSource.readAddresses(),
      throwsA(isA<CacheException>()),
    );
    storage.values[AddressLocalDataSourceImpl.cacheKey] = '[1, 2]';
    await expectLater(
      dataSource.readAddresses(),
      throwsA(isA<CacheException>()),
    );
  });

  test('a malformed cached row is skipped', () async {
    storage.values[AddressLocalDataSourceImpl.cacheKey] = jsonEncode({
      'ownerId': owner,
      'addresses': [
        addressJson(n: 1),
        {'label': 'no id'},
      ],
    });
    expect(
      (await dataSource.readAddresses()).addresses.single.id,
      addressId(1),
    );
  });

  test('a refused write throws CacheException', () async {
    storage.failWrites = true;
    await expectLater(
      dataSource.saveAddresses(CachedAddressBookModel.empty),
      throwsA(isA<CacheException>()),
    );
    await expectLater(dataSource.clear(), throwsA(isA<CacheException>()));
  });
}
