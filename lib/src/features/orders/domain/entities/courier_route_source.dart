/// Who drew a ride's road — the map owes each its credit line.
enum CourierRouteSource {
  /// Google's roads: the Google logo on the map is the credit.
  google,

  /// OpenStreetMap roads (OSRM): "© OpenStreetMap contributors".
  openStreetMap,

  /// Streets estimated on the device when no road service answered.
  estimated;

  /// The credit line's translation key; `null` when the map already shows it.
  String? get creditKey => switch (this) {
    CourierRouteSource.google => null,
    CourierRouteSource.openStreetMap => 'orders.live_route_osm',
    CourierRouteSource.estimated => 'orders.live_route_estimated',
  };
}
