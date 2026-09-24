import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/address_repository.dart';

class DeleteAddressParams extends Equatable {
  const DeleteAddressParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// `DELETE /v1/account/addresses/:addressId`.
class DeleteAddressUseCase implements UseCase<Unit, DeleteAddressParams> {
  const DeleteAddressUseCase(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteAddressParams params) =>
      _repository.deleteAddress(params.id);
}
