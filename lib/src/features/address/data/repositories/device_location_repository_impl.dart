import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/device_location.dart';
import '../../domain/repositories/device_location_repository.dart';
import '../datasources/device_location_data_source.dart';
import '../mappers/device_location_mapper.dart';

class DeviceLocationRepositoryImpl
    with BaseRepositoryMixin
    implements DeviceLocationRepository {
  const DeviceLocationRepositoryImpl(this._device);

  final DeviceLocationDataSource _device;

  @override
  Future<Either<Failure, DeviceLocation>> lastKnown() =>
      execute(() async => (await _device.lastKnown()).toEntity());

  @override
  Future<Either<Failure, DeviceLocation>> current({required bool ask}) =>
      execute(() async => (await _device.current(ask: ask)).toEntity());

  @override
  Future<Either<Failure, bool>> openSettings(LocationSettingsTarget target) =>
      execute(
        () => switch (target) {
          LocationSettingsTarget.device => _device.openDeviceSettings(),
          LocationSettingsTarget.app => _device.openAppSettings(),
        },
      );
}
