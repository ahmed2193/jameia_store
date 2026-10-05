import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/device_location.dart';
import '../repositories/device_location_repository.dart';

class OpenLocationSettingsParams extends Equatable {
  const OpenLocationSettingsParams(this.target);

  final LocationSettingsTarget target;

  @override
  List<Object?> get props => [target];
}

/// Opens the settings screen that can turn location on for the app.
class OpenLocationSettingsUseCase
    implements UseCase<bool, OpenLocationSettingsParams> {
  const OpenLocationSettingsUseCase(this._repository);

  final DeviceLocationRepository _repository;

  @override
  Future<Either<Failure, bool>> call(OpenLocationSettingsParams params) =>
      _repository.openSettings(params.target);
}
