import '../constants/app_env.dart';

/// Third-party map services the app calls through [ExternalApiConsumer]
/// (full URLs: they are not on the Hero host).
abstract final class ExternalEndPoints {
  /// Google Routes API — `POST` a route request, get legs + polylines.
  static const String googleComputeRoutes =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  static const String _googlePlaces = 'https://places.googleapis.com/v1';

  /// Google Places API (New) — `POST` what was typed, get place predictions.
  static const String googlePlacesAutocomplete =
      '$_googlePlaces/places:autocomplete';

  /// Google Places API (New) — `GET` one place by its id.
  static String googlePlace(String placeId) =>
      '$_googlePlaces/places/${Uri.encodeComponent(placeId)}';

  /// OSRM route service, car profile, through [coordinates]
  /// (`lng,lat;lng,lat;…`).
  static String osrmRoute(String coordinates) =>
      '${AppEnv.osrmBaseUrl}/route/v1/driving/$coordinates';
}
