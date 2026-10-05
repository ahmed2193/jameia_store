import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/device_location.dart';
import '../models/device_location_model.dart';

extension DeviceLocationMapper on DeviceLocationModel {
  DeviceLocation toEntity() {
    final lat = this.lat;
    final lng = this.lng;
    if (reading == DeviceLocationReading.fix && lat != null && lng != null) {
      return DeviceLocation.found(GeoPointEntity(lat: lat, lng: lng));
    }
    return DeviceLocation.missing(switch (reading) {
      DeviceLocationReading.serviceOff => DeviceLocationStatus.serviceOff,
      DeviceLocationReading.denied => DeviceLocationStatus.denied,
      DeviceLocationReading.deniedForever => DeviceLocationStatus.blocked,
      DeviceLocationReading.fix ||
      DeviceLocationReading.noFix => DeviceLocationStatus.unavailable,
    });
  }
}
