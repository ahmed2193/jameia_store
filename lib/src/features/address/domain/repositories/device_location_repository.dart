import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/device_location.dart';

/// The device's own position (GPS / network location).
abstract class DeviceLocationRepository {
  /// The last position the device knows, at once — never asks for the
  /// permission and never waits for a fix.
  Future<Either<Failure, DeviceLocation>> lastKnown();

  /// A fresh fix. With [ask] the permission prompt shows when the customer
  /// has not answered it yet.
  Future<Either<Failure, DeviceLocation>> current({required bool ask});

  /// Opens the settings screen [target]; whether it opened.
  Future<Either<Failure, bool>> openSettings(LocationSettingsTarget target);
}
