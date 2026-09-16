import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'keeta_geocode.dart';

/// Device current-location helper for the address map-picker initial centre
/// (KeeTa `SLLocation.getLocation` / `address_mainpage_address_poinull_currentlocation`).
///
/// Requests the location permission on demand and returns the device position;
/// falls back to [KeetaGeocode.base] (Kuwait City) whenever the service is off,
/// permission is denied, or the fix times out — so the picker always opens
/// somewhere sensible and never blocks.
class KeetaLocation {
  KeetaLocation._();

  /// The current device coordinate, or [KeetaGeocode.base] on any failure.
  static Future<LatLng> current({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return KeetaGeocode.base;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return KeetaGeocode.base;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(timeout);
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return KeetaGeocode.base;
    }
  }
}
