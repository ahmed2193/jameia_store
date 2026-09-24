import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address_book.dart';
import '../repositories/address_repository.dart';

/// `GET /v1/account/addresses` as a book in display order.
class GetAddressesUseCase implements UseCase<AddressBook, NoParams> {
  const GetAddressesUseCase(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, AddressBook>> call(NoParams params) async =>
      (await _repository.fetchAddresses()).map(AddressBook.of);
}
