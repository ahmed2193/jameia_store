import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/device_location.dart';
import '../repositories/device_location_repository.dart';

/// The device's last known position, at once (no prompt, no waiting): the
/// map opens there while a fresh fix is on its way.
class GetLastKnownLocationUseCase implements UseCase<DeviceLocation, NoParams> {
  const GetLastKnownLocationUseCase(this._repository);

  final DeviceLocationRepository _repository;

  @override
  Future<Either<Failure, DeviceLocation>> call(NoParams params) =>
      _repository.lastKnown();
}
