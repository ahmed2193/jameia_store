import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/device_location.dart';
import '../repositories/device_location_repository.dart';

class LocateDeviceParams extends Equatable {
  const LocateDeviceParams({required this.ask});

  /// Show the permission prompt when it was never answered.
  final bool ask;

  @override
  List<Object?> get props => [ask];
}

/// Where the device is now, or why it cannot tell.
class LocateDeviceUseCase
    implements UseCase<DeviceLocation, LocateDeviceParams> {
  const LocateDeviceUseCase(this._repository);

  final DeviceLocationRepository _repository;

  @override
  Future<Either<Failure, DeviceLocation>> call(LocateDeviceParams params) =>
      _repository.current(ask: params.ask);
}
