import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address_update.dart';
import '../repositories/address_repository.dart';

class UpdateAddressParams extends Equatable {
  const UpdateAddressParams({required this.id, required this.update});

  final String id;
  final AddressUpdate update;

  @override
  List<Object?> get props => [id, update];
}

/// `PATCH /v1/account/addresses/:addressId`. An empty update is refused so the
/// UI never fires a no-op request.
class UpdateAddressUseCase
    implements UseCase<JameiaAddressEntity, UpdateAddressParams> {
  const UpdateAddressUseCase(this._repository);

  static const String nothingToSaveMessage = 'Nothing to save';

  final AddressRepository _repository;

  @override
  Future<Either<Failure, JameiaAddressEntity>> call(
    UpdateAddressParams params,
  ) async {
    if (params.update.isEmpty) {
      return const Left(UnexpectedFailure(nothingToSaveMessage));
    }
    return _repository.updateAddress(params.id, params.update);
  }
}
