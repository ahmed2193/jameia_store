import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/address_repository.dart';

/// Forgets the address book saved on this device (the session ended).
class ClearCachedAddressesUseCase implements UseCase<Unit, NoParams> {
  const ClearCachedAddressesUseCase(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.clearCachedAddresses();
}
