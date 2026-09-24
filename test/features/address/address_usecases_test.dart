import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/jameia_address_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_book.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_draft.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_update.dart';
import 'package:jameia_mart/src/features/address/domain/entities/cached_address_book.dart';
import 'package:jameia_mart/src/features/address/domain/repositories/address_repository.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/add_address_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/clear_cached_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/delete_address_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/get_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/get_cached_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/save_cached_addresses_usecase.dart';
import 'package:jameia_mart/src/features/address/domain/usecases/update_address_usecase.dart';

import 'address_test_fakes.dart';

class _FakeRepository implements AddressRepository {
  Either<Failure, List<JameiaAddressEntity>> list = Right([
    address(n: 1),
    address(n: 2, isDefault: true),
  ]);
  Either<Failure, JameiaAddressEntity> saved = Right(address(n: 3));
  Either<Failure, Unit> done = const Right(unit);
  final List<String> calls = [];
  List<JameiaAddressEntity>? cached;
  String? cachedOwner;
  AddressDraft? draft;
  AddressUpdate? update;
  String? id;

  @override
  Future<Either<Failure, List<JameiaAddressEntity>>> fetchAddresses() async {
    calls.add('fetch');
    return list;
  }

  @override
  Future<Either<Failure, CachedAddressBook>> getCachedAddresses() async {
    calls.add('cached');
    return list.map(
      (addresses) =>
          CachedAddressBook(ownerId: cachedOwner, addresses: addresses),
    );
  }

  @override
  Future<Either<Failure, Unit>> saveCachedAddresses(
    List<JameiaAddressEntity> addresses, {
    String? ownerId,
  }) async {
    calls.add('save');
    cached = addresses;
    cachedOwner = ownerId;
    return done;
  }

  @override
  Future<Either<Failure, Unit>> clearCachedAddresses() async {
    calls.add('clear');
    return done;
  }

  @override
  Future<Either<Failure, JameiaAddressEntity>> addAddress(
    AddressDraft draft,
  ) async {
    calls.add('add');
    this.draft = draft;
    return saved;
  }

  @override
  Future<Either<Failure, JameiaAddressEntity>> updateAddress(
    String id,
    AddressUpdate update,
  ) async {
    calls.add('update');
    this.id = id;
    this.update = update;
    return saved;
  }

  @override
  Future<Either<Failure, Unit>> deleteAddress(String id) async {
    calls.add('delete');
    this.id = id;
    return done;
  }
}

void main() {
  late _FakeRepository repository;

  setUp(() => repository = _FakeRepository());

  const validDraft = AddressDraft(
    city: 'Salmiya',
    block: '7',
    street: '22',
    building: '5',
    phone: '50001122',
  );

  test('GetAddressesUseCase orders the server list as a book', () async {
    final result = await GetAddressesUseCase(repository)(const NoParams());
    expect(
      result.getOrElse(() => AddressBook.empty).addresses.first.id,
      addressId(2),
    );
    expect(repository.calls, ['fetch']);
  });

  test('GetAddressesUseCase passes a failure through', () async {
    repository.list = const Left(UnauthorizedFailure());
    expect(
      await GetAddressesUseCase(repository)(const NoParams()),
      const Left<Failure, AddressBook>(UnauthorizedFailure()),
    );
  });

  test(
    'GetCachedAddressesUseCase reads the device copy and its owner',
    () async {
      repository.cachedOwner = 'aaaaaaaaaaaaaaaaaaaaaaaa';
      final result = await GetCachedAddressesUseCase(repository)(
        const NoParams(),
      );
      final copy = result.getOrElse(() => CachedAddressBook.none);
      expect(copy.ownerId, 'aaaaaaaaaaaaaaaaaaaaaaaa');
      expect(copy.book.addresses.first.id, addressId(2)); // default first
      expect(repository.calls, ['cached']);
    },
  );

  test(
    'AddAddressUseCase refuses an invalid draft before the network',
    () async {
      final result = await AddAddressUseCase(repository)(
        const AddAddressParams(draft: AddressDraft()),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    },
  );

  test('AddAddressUseCase sends a valid draft', () async {
    final result = await AddAddressUseCase(repository)(
      const AddAddressParams(draft: validDraft),
    );
    expect(result, Right<Failure, JameiaAddressEntity>(address(n: 3)));
    expect(repository.draft, validDraft);
  });

  test(
    'UpdateAddressUseCase refuses an empty update before the network',
    () async {
      final result = await UpdateAddressUseCase(repository)(
        UpdateAddressParams(id: addressId(1), update: const AddressUpdate()),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    },
  );

  test('UpdateAddressUseCase sends id + update unchanged', () async {
    const update = AddressUpdate(street: '23');
    await UpdateAddressUseCase(repository)(
      UpdateAddressParams(id: addressId(1), update: update),
    );
    expect(repository.id, addressId(1));
    expect(repository.update, update);
  });

  test('DeleteAddressUseCase passes the id and the result through', () async {
    repository.done = const Left(NetworkFailure());
    expect(
      await DeleteAddressUseCase(repository)(
        DeleteAddressParams(id: addressId(4)),
      ),
      const Left<Failure, Unit>(NetworkFailure()),
    );
    expect(repository.id, addressId(4));
  });

  test(
    'SaveCachedAddressesUseCase saves the book rows for the owner',
    () async {
      final book = AddressBook.of([address(n: 1)]);
      await SaveCachedAddressesUseCase(repository)(
        SaveCachedAddressesParams(
          book: book,
          ownerId: 'bbbbbbbbbbbbbbbbbbbbbbbb',
        ),
      );
      expect(repository.cached, book.addresses);
      expect(repository.cachedOwner, 'bbbbbbbbbbbbbbbbbbbbbbbb');
    },
  );

  test(
    'CachedAddressBook.belongsTo refuses only a different known customer',
    () {
      const mine = CachedAddressBook(ownerId: 'aaaaaaaaaaaaaaaaaaaaaaaa');
      expect(mine.belongsTo('aaaaaaaaaaaaaaaaaaaaaaaa'), isTrue);
      expect(mine.belongsTo(null), isTrue);
      expect(mine.belongsTo('bbbbbbbbbbbbbbbbbbbbbbbb'), isFalse);
      expect(
        CachedAddressBook.none.belongsTo('bbbbbbbbbbbbbbbbbbbbbbbb'),
        isTrue,
      );
    },
  );

  test('ClearCachedAddressesUseCase clears the device copy', () async {
    expect(
      await ClearCachedAddressesUseCase(repository)(const NoParams()),
      const Right<Failure, Unit>(unit),
    );
    expect(repository.calls, ['clear']);
  });
}
