import 'package:equatable/equatable.dart';

import 'service_region_item_entity.dart';

/// Snapshot for the serviceable-region picker (`choose_location_page`): the
/// hard-coded service-region anchors plus the repository's currently-active
/// two-letter region code (used to seed the default selection and to detect a
/// region SWITCH on confirm).
///
/// Now framework-free: it holds [ServiceRegionItemEntity]s (a `GeoPointEntity`
/// anchor) instead of the core `ServiceRegionItem` (which leaked
/// `google_maps_flutter`'s `LatLng` through `core/utils/jameia_geocode`).
class RegionOptions extends Equatable {
  const RegionOptions({required this.regions, required this.activeRegion});

  /// All serviceable regions (the hard-coded anchors from `JameiaGeocode`).
  final List<ServiceRegionItemEntity> regions;

  /// The repository's active two-letter region code (`KW` by default).
  final String activeRegion;

  @override
  List<Object?> get props => [regions, activeRegion];
}
