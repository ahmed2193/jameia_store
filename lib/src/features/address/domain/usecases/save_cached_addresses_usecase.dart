import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address_book.dart';
import '../repositories/address_repository.dart';

class SaveCachedAddressesParams extends Equatable {
  const SaveCachedAddressesParams({required this.book, this.ownerId});

  final AddressBook book;

  /// The customer the book belongs to; `null` when not known yet.
  final String? ownerId;

  @override
  List<Object?> get props => [book, ownerId];
}

/// Keeps [SaveCachedAddressesParams.book] on this device for the next launch
/// and for offline sessions.
class SaveCachedAddressesUseCase
    implements UseCase<Unit, SaveCachedAddressesParams> {
  const SaveCachedAddressesUseCase(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveCachedAddressesParams params) =>
      _repository.saveCachedAddresses(
        params.book.addresses,
        ownerId: params.ownerId,
      );
}
