import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';

/// Why the device could, or could not, say where it is.
enum DeviceLocationStatus {
  /// A fix: [DeviceLocation.point] is set.
  found,

  /// Location is switched off on the device.
  serviceOff,

  /// The customer said no (the app may ask again).
  denied,

  /// The customer said "never" — only the app's settings can change it.
  blocked,

  /// No fix in time, or no last position to give.
  unavailable,
}

/// Where the device is, or why it cannot tell.
class DeviceLocation extends Equatable {
  const DeviceLocation.found(GeoPointEntity this.point)
    : status = DeviceLocationStatus.found;

  const DeviceLocation.missing(this.status) : point = null;

  final DeviceLocationStatus status;
  final GeoPointEntity? point;

  /// Whether the customer let the app read the location (the map may show
  /// the "you are here" dot).
  bool get isAllowed =>
      status == DeviceLocationStatus.found ||
      status == DeviceLocationStatus.unavailable;

  @override
  List<Object?> get props => [status, point];
}

/// The settings screen that can turn location on for the app.
enum LocationSettingsTarget {
  /// The device's location switch.
  device,

  /// The app's own permissions.
  app,
}
