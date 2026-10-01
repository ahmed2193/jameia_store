/// How the rider travels — shown on the rider card, since it says how fast
/// the last stretch can go. [other] is a value this build does not know.
enum CourierVehicle {
  motorbike,
  car,
  bicycle,
  other;

  /// i18n key of its name, or `null` when there is nothing to say.
  String? get labelKey => switch (this) {
    motorbike => 'orders.live_vehicle_motorbike',
    car => 'orders.live_vehicle_car',
    bicycle => 'orders.live_vehicle_bicycle',
    other => null,
  };
}
