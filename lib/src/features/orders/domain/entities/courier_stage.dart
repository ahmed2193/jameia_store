/// Where a ride stands, in the customer's words: a rider is being found,
/// rides to the store, collects the order, brings it over, is almost at the
/// door, is there.
enum CourierStage {
  assigning,
  toStore,
  atStore,
  onTheWay,
  nearby,
  arrived;

  /// i18n key of the line under the time; widgets call `.tr()` on it.
  String get labelKey => switch (this) {
    assigning => 'orders.live_stage_assigning',
    toStore => 'orders.live_stage_to_store',
    atStore => 'orders.live_stage_at_store',
    onTheWay => 'orders.live_stage_on_the_way',
    nearby => 'orders.live_stage_nearby',
    arrived => 'orders.live_stage_arrived',
  };

  /// A rider is on the map (found, not yet gone).
  bool get hasRider => this != assigning;

  /// The rider carries the order (left the store with it).
  bool get delivering => this == onTheWay || this == nearby || this == arrived;
}
