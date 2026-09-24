import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address_draft.dart';
import '../repositories/address_repository.dart';

class AddAddressParams extends Equatable {
  const AddAddressParams({required this.draft});

  final AddressDraft draft;

  @override
  List<Object?> get props => [draft];
}

/// `POST /v1/account/addresses`. A draft that breaks a field rule is refused
/// before the network.
class AddAddressUseCase
    implements UseCase<JameiaAddressEntity, AddAddressParams> {
  const AddAddressUseCase(this._repository);

  static const String invalidDraftMessage = 'Address form is not valid';

  final AddressRepository _repository;

  @override
  Future<Either<Failure, JameiaAddressEntity>> call(
    AddAddressParams params,
  ) async {
    if (!params.draft.isValid) {
      return const Left(UnexpectedFailure(invalidDraftMessage));
    }
    return _repository.addAddress(params.draft);
  }
}
