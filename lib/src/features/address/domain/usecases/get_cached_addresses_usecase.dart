import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cached_address_book.dart';
import '../repositories/address_repository.dart';

/// The address book saved on this device and the customer it belongs to.
class GetCachedAddressesUseCase
    implements UseCase<CachedAddressBook, NoParams> {
  const GetCachedAddressesUseCase(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, CachedAddressBook>> call(NoParams params) =>
      _repository.getCachedAddresses();
}
