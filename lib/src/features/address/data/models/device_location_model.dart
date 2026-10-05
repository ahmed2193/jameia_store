/// What the device's location service answered.
enum DeviceLocationReading { fix, serviceOff, denied, deniedForever, noFix }

/// A position from the device, or why there is none.
class DeviceLocationModel {
  const DeviceLocationModel.fix({
    required double this.lat,
    required double this.lng,
  }) : reading = DeviceLocationReading.fix;

  const DeviceLocationModel.none(this.reading) : lat = null, lng = null;

  final DeviceLocationReading reading;
  final double? lat;
  final double? lng;
}
