import '../constants/app_env.dart';

/// Third-party map services the app calls through [ExternalApiConsumer]
/// (full URLs: they are not on the Hero host).
abstract final class ExternalEndPoints {
  /// Google Routes API — `POST` a route request, get legs + polylines.
  static const String googleComputeRoutes =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// OSRM route service, car profile, through [coordinates]
  /// (`lng,lat;lng,lat;…`).
  static String osrmRoute(String coordinates) =>
      '${AppEnv.osrmBaseUrl}/route/v1/driving/$coordinates';
}
