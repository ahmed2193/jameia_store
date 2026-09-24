import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/models/customer_model.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/storage/auth_tokens.dart';
import 'package:jameia_mart/src/features/auth/data/datasources/auth_local_data_source.dart';

import '../../core/network/network_test_fakes.dart';
import '../address/address_test_fakes.dart' show InMemoryLocalStorage;

void main() {
  late InMemorySessionStore session;
  late RecordingExpiryNotifier expiry;
  late InMemoryLocalStorage storage;
  late AuthLocalDataSourceImpl dataSource;

  const customer = CustomerModel(
    id: '507f1f77bcf86cd799439011',
    phone: '+96512345678',
    nameEn: 'Ahmed',
    nameAr: 'Ahmed',
    email: 'ahmed@jm3eia.com',
    language: 'ar',
    wallet: 1250,
    loyaltyPoints: 320,
    proActive: true,
    proExpiresAt: '2027-01-01T00:00:00.000Z',
    dateOfBirth: '1990-05-17',
    gender: 'male',
    householdSize: 4,
    marketingPush: false,
  );

  setUp(() {
    session = InMemorySessionStore()
      ..cartToken = 'cart'
      ..assistantGuestKey = 'g' * 32;
    expiry = RecordingExpiryNotifier();
    storage = InMemoryLocalStorage();
    dataSource = AuthLocalDataSourceImpl(session, expiry, storage);
  });

  test('saveSession stores the pair AND drops the guest identities', () async {
    await dataSource.saveSession(
      const AuthTokens(accessToken: 'a', refreshToken: 'r'),
    );
    expect(session.accessToken, 'a');
    expect(session.refreshToken, 'r');
    expect(session.cartToken, isNull);
    expect(session.assistantGuestKey, isNull);
    expect(await dataSource.hasSession(), isTrue);
  });

  test('clearSession forgets the pair only', () async {
    await dataSource.saveSession(
      const AuthTokens(accessToken: 'a', refreshToken: 'r'),
    );
    await session.saveCartToken('cart2');
    await dataSource.clearSession();
    expect(await dataSource.hasSession(), isFalse);
    expect(session.cartToken, 'cart2');
  });

  test('onSessionExpired is the notifier stream', () {
    expect(dataSource.onSessionExpired, same(expiry.onSessionExpired));
  });

  group('device copy of the customer', () {
    test('nothing saved → null', () async {
      expect(await dataSource.readCustomer(), isNull);
    });

    test('saves the API row under one key and reads it back', () async {
      await dataSource.saveCustomer(customer);

      final stored = jsonDecode(
        storage.values[AuthLocalDataSourceImpl.customerKey]! as String,
      );
      expect(stored, customer.toJson());

      final read = await dataSource.readCustomer();
      expect(read!.toJson(), customer.toJson());
    });

    test('clear removes it', () async {
      await dataSource.saveCustomer(customer);
      await dataSource.clearCustomer();

      expect(
        storage.values.containsKey(AuthLocalDataSourceImpl.customerKey),
        isFalse,
      );
      expect(await dataSource.readCustomer(), isNull);
    });

    test('a corrupt copy is a CacheException', () async {
      storage.values[AuthLocalDataSourceImpl.customerKey] = '{not json';
      expect(dataSource.readCustomer(), throwsA(isA<CacheException>()));
    });

    test('a copy without an id is a CacheException', () async {
      storage.values[AuthLocalDataSourceImpl.customerKey] = jsonEncode({
        'name': 'x',
      });
      expect(dataSource.readCustomer(), throwsA(isA<CacheException>()));
    });

    test('a refused write is a CacheException', () async {
      storage.failWrites = true;
      expect(dataSource.saveCustomer(customer), throwsA(isA<CacheException>()));
    });
  });
}
