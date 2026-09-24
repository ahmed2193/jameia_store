import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/address/data/datasources/address_local_data_source.dart';
import 'package:jameia_mart/src/features/address/data/datasources/address_remote_data_source.dart';
import 'package:jameia_mart/src/features/address/data/models/address_model.dart';
import 'package:jameia_mart/src/features/address/data/models/cached_address_book_model.dart';
import 'package:jameia_mart/src/features/address/data/repositories/address_repository_impl.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_draft.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_update.dart';
import 'package:jameia_mart/src/features/address/domain/entities/cached_address_book.dart';

import 'address_test_fakes.dart';

class _FakeRemote implements AddressRemoteDataSource {
  Object? error;
  List<AddressModel> rows = [AddressModel.fromJson(addressJson())];
  AddressModel saved = AddressModel.fromJson(addressJson(n: 9));
  Map<String, Object?>? lastBody;
  String? lastId;
  int calls = 0;

  Future<void> _call() async {
    calls++;
    if (error != null) throw error!;
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    await _call();
    return rows;
  }

  @override
  Future<AddressModel> createAddress(Map<String, Object?> body) async {
    lastBody = body;
    await _call();
    return saved;
  }

  @override
  Future<AddressModel> updateAddress(
    String id,
    Map<String, Object?> body,
  ) async {
    lastId = id;
    lastBody = body;
    await _call();
    return saved;
  }

  @override
  Future<void> deleteAddress(String id) async {
    lastId = id;
    await _call();
  }
}

class _FakeLocal implements AddressLocalDataSource {
  Object? error;
  CachedAddressBookModel copy = CachedAddressBookModel.empty;
  int clears = 0;

  @override
  Future<CachedAddressBookModel> readAddresses() async {
    if (error != null) throw error!;
    return copy;
  }

  @override
  Future<void> saveAddresses(CachedAddressBookModel copy) async {
    if (error != null) throw error!;
    this.copy = copy;
  }

  @override
  Future<void> clear() async {
    if (error != null) throw error!;
    clears++;
    copy = CachedAddressBookModel.empty;
  }
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late AddressRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repository = AddressRepositoryImpl(remote: remote, local: local);
  });

  test('fetchAddresses maps rows and never writes the device copy', () async {
    final result = await repository.fetchAddresses();
    expect(result.getOrElse(() => []).single.id, addressId(1));
    expect(local.copy.addresses, isEmpty);
  });

  test('cache: save → read round trip with the owner, clear', () async {
    const owner = 'aaaaaaaaaaaaaaaaaaaaaaaa';
    final entities = [address(n: 1, isDefault: true), address(n: 2)];
    expect(
      await repository.saveCachedAddresses(entities, ownerId: owner),
      const Right(unit),
    );
    final cached = (await repository.getCachedAddresses()).getOrElse(
      () => CachedAddressBook.none,
    );
    expect(cached, CachedAddressBook(ownerId: owner, addresses: entities));
    expect(await repository.clearCachedAddresses(), const Right(unit));
    expect(local.clears, 1);
  });

  test(
    'updateAddress: 404 stays a failure (only delete treats it as done)',
    () async {
      remote.error = const NotFoundException(
        'Address not found',
        code: 'RESOURCE_NOT_FOUND',
      );
      final result = await repository.updateAddress(
        addressId(3),
        const AddressUpdate(floor: '1'),
      );
      expect(
        result.fold((f) => f, (_) => null),
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 404),
      );
    },
  );

  test(
    'addAddress POSTs the draft body and returns the created address',
    () async {
      const draft = AddressDraft(
        city: 'Salmiya',
        block: '7',
        street: '22',
        building: '5',
        phone: '50001122',
      );
      final result = await repository.addAddress(draft);
      expect(result.getOrElse(() => address()).id, addressId(9));
      expect(remote.lastBody?['city'], 'Salmiya');
      expect(remote.lastBody?['phone'], '+96550001122');
    },
  );

  test('updateAddress PATCHes only the changed keys', () async {
    await repository.updateAddress(
      addressId(3),
      const AddressUpdate(street: '23'),
    );
    expect(remote.lastId, addressId(3));
    expect(remote.lastBody, {'street': '23'});
  });

  test('deleteAddress: 404 counts as deleted', () async {
    remote.error = const NotFoundException('gone', code: 'RESOURCE_NOT_FOUND');
    expect(await repository.deleteAddress(addressId(5)), const Right(unit));
    expect(remote.lastId, addressId(5));
  });

  group('exception → failure', () {
    final cases = <Object, Matcher>{
      const UnauthorizedException('Sign in', code: 'AUTHENTICATION_REQUIRED'):
          isA<UnauthorizedFailure>(),
      const NoInternetConnectionException(): isA<NetworkFailure>(),
      const RequestTimeoutException(): isA<TimeoutFailure>(),
      const ParsingException('bad'): isA<ParsingFailure>(),
      const BadRequestException(
        'Invalid',
        code: 'VALIDATION_ERROR',
      ): isA<ServerFailure>().having(
        (f) => f.code,
        'code',
        'VALIDATION_ERROR',
      ),
      const ServerException(
        'Boom',
        statusCode: 500,
        code: 'INTERNAL_ERROR',
      ): isA<ServerFailure>()
          .having((f) => f.statusCode, 'statusCode', 500)
          .having((f) => f.code, 'code', 'INTERNAL_ERROR'),
    };

    for (final entry in cases.entries) {
      test('${entry.key.runtimeType} on every remote call', () async {
        remote.error = entry.key;
        Failure? failureOf(Either<Failure, Object?> result) =>
            result.fold((failure) => failure, (_) => null);
        expect(failureOf(await repository.fetchAddresses()), entry.value);
        expect(
          failureOf(await repository.addAddress(const AddressDraft())),
          entry.value,
        );
        expect(
          failureOf(
            await repository.updateAddress(
              addressId(1),
              const AddressUpdate(floor: '1'),
            ),
          ),
          entry.value,
        );
        expect(
          failureOf(await repository.deleteAddress(addressId(1))),
          entry.value,
        );
      });
    }

    test('a broken device copy → CacheFailure', () async {
      local.error = const CacheException('unreadable');
      expect(
        (await repository.getCachedAddresses()).fold((f) => f, (_) => null),
        isA<CacheFailure>(),
      );
      expect(
        (await repository.saveCachedAddresses(const []))
            .fold((f) => f, (_) => null),
        isA<CacheFailure>(),
      );
    });
  });
}
