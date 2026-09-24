import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';

/// Framework-free serviceable-region row for the region picker.
///
/// Mirrors the core `ServiceRegionItem` (from `core/utils/jameia_geocode`) but
/// drops its `google_maps_flutter` `LatLng anchor` in favour of a plain
/// [GeoPointEntity], so the domain stays framework-free. The data layer maps
/// between the two (see `data/mappers/service_region_mapper.dart`).
class ServiceRegionItemEntity extends Equatable {
  const ServiceRegionItemEntity({
    required this.region,
    required this.regionName,
    required this.cityId,
    required this.cityName,
    required this.anchor,
    required this.enabled,
  });

  /// Two-letter region code (HK/SA/AE/QA/KW/BH/BR).
  final String region;

  /// Region/country display name.
  final String regionName;

  /// Jameia numeric city id (as string).
  final String cityId;

  /// City display name (the subtitle).
  final String cityName;

  /// City-centre coordinate (was `LatLng`, now a framework-free point).
  final GeoPointEntity anchor;

  /// Gating flag (BH/BR are feature-flagged off by default).
  final bool enabled;

  @override
  List<Object?> get props => [
    region,
    regionName,
    cityId,
    cityName,
    anchor,
    enabled,
  ];
}
