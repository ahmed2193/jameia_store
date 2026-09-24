import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_update.dart';
import '../../domain/entities/cached_address_book.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_local_data_source.dart';
import '../datasources/address_remote_data_source.dart';
import '../mappers/address_body_mapper.dart';
import '../mappers/address_mapper.dart';
import '../models/cached_address_book_model.dart';

class AddressRepositoryImpl
    with BaseRepositoryMixin
    implements AddressRepository {
  const AddressRepositoryImpl({required this._remote, required this._local});

  final AddressRemoteDataSource _remote;
  final AddressLocalDataSource _local;

  @override
  Future<Either<Failure, CachedAddressBook>> getCachedAddresses() =>
      execute(() async {
        final copy = await _local.readAddresses();
        return CachedAddressBook(
          ownerId: copy.ownerId,
          addresses: copy.addresses.toEntities(),
        );
      });

  @override
  Future<Either<Failure, Unit>> saveCachedAddresses(
    List<JameiaAddressEntity> addresses, {
    String? ownerId,
  }) => execute(() async {
    await _local.saveAddresses(
      CachedAddressBookModel(ownerId: ownerId, addresses: addresses.toModels()),
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> clearCachedAddresses() => execute(() async {
    await _local.clear();
    return unit;
  });

  @override
  Future<Either<Failure, List<JameiaAddressEntity>>> fetchAddresses() =>
      execute(() async => (await _remote.getAddresses()).toEntities());

  @override
  Future<Either<Failure, JameiaAddressEntity>> addAddress(AddressDraft draft) =>
      execute(
        () async => (await _remote.createAddress(draft.toBody())).toEntity(),
      );

  @override
  Future<Either<Failure, JameiaAddressEntity>> updateAddress(
    String id,
    AddressUpdate update,
  ) => execute(
    () async => (await _remote.updateAddress(id, update.toBody())).toEntity(),
  );

  @override
  Future<Either<Failure, Unit>> deleteAddress(String id) => execute(() async {
    try {
      await _remote.deleteAddress(id);
    } on NotFoundException {
      // Deleted elsewhere already: the state the customer asked for holds.
    }
    return unit;
  });
}
