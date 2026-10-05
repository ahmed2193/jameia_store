import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/device_location_model.dart';

/// The device's location service (GPS / network): the permission, a fresh
/// fix, the last known one and the settings screens that turn it on.
abstract class DeviceLocationDataSource {
  /// The last known position, at once; never asks for the permission.
  Future<DeviceLocationModel> lastKnown();

  /// A fresh fix, given [fixTimeLimit]; past it, the last known position.
  /// With [ask] the permission prompt shows when it was never answered.
  Future<DeviceLocationModel> current({required bool ask});

  /// The device's location switch.
  Future<bool> openDeviceSettings();

  /// The app's permissions.
  Future<bool> openAppSettings();
}

class DeviceLocationDataSourceImpl implements DeviceLocationDataSource {
  const DeviceLocationDataSourceImpl();

  /// A fix good enough to put a pin on a building, given this long.
  static const Duration fixTimeLimit = Duration(seconds: 8);

  @override
  Future<DeviceLocationModel> lastKnown() async {
    final refused = await _refusal(ask: false);
    if (refused != null) return refused;
    return _lastOrNone();
  }

  @override
  Future<DeviceLocationModel> current({required bool ask}) async {
    final refused = await _refusal(ask: ask);
    if (refused != null) return refused;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: fixTimeLimit,
        ),
      );
      return _fix(position);
    } on TimeoutException {
      return _lastOrNone();
    } on LocationServiceDisabledException {
      return const DeviceLocationModel.none(DeviceLocationReading.serviceOff);
    } on PermissionDeniedException {
      return const DeviceLocationModel.none(DeviceLocationReading.denied);
    }
  }

  @override
  Future<bool> openDeviceSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Why the app may not read the location now, or `null` when it may.
  Future<DeviceLocationModel?> _refusal({required bool ask}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const DeviceLocationModel.none(DeviceLocationReading.serviceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && ask) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.whileInUse || LocationPermission.always => null,
      LocationPermission.deniedForever => const DeviceLocationModel.none(
        DeviceLocationReading.deniedForever,
      ),
      LocationPermission.denied || LocationPermission.unableToDetermine =>
        const DeviceLocationModel.none(DeviceLocationReading.denied),
    };
  }

  Future<DeviceLocationModel> _lastOrNone() async {
    final last = await Geolocator.getLastKnownPosition();
    return last == null
        ? const DeviceLocationModel.none(DeviceLocationReading.noFix)
        : _fix(last);
  }

  static DeviceLocationModel _fix(Position position) =>
      DeviceLocationModel.fix(lat: position.latitude, lng: position.longitude);
}
