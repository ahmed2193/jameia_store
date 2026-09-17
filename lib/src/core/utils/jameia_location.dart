import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'jameia_geocode.dart';

/// Device current-location helper for the address map-picker initial centre
/// (Jameia `SLLocation.getLocation` / `address_mainpage_address_poinull_currentlocation`).
///
/// Requests the location permission on demand and returns the device position;
/// falls back to [JameiaGeocode.base] (Kuwait City) whenever the service is off,
/// permission is denied, or the fix times out — so the picker always opens
/// somewhere sensible and never blocks.
class JameiaLocation {
  JameiaLocation._();

  /// The current device coordinate, or [JameiaGeocode.base] on any failure.
  static Future<LatLng> current({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return JameiaGeocode.base;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return JameiaGeocode.base;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(timeout);
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return JameiaGeocode.base;
    }
  }
}
