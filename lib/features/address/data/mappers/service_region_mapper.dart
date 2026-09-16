import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/keeta_geocode.dart' show ServiceRegionItem;
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/service_region_item_entity.dart';

/// DTO ↔ entity mapping for the serviceable-region rows. Lives in the data
/// layer, so the `google_maps_flutter` `LatLng anchor` on the core
/// [ServiceRegionItem] is confined here (converted to/from [GeoPointEntity])
/// and never crosses into the framework-free domain.
extension ServiceRegionMapper on ServiceRegionItem {
  ServiceRegionItemEntity toEntity() => ServiceRegionItemEntity(
        region: region,
        regionName: regionName,
        cityId: cityId,
        cityName: cityName,
        anchor: GeoPointEntity(lat: anchor.latitude, lng: anchor.longitude),
        enabled: enabled,
      );
}

/// Convenience for mapping the whole list.
extension ServiceRegionListMapper on List<ServiceRegionItem> {
  List<ServiceRegionItemEntity> toEntities() =>
      map((r) => r.toEntity()).toList();
}

/// Reverse map — rebuild the core [ServiceRegionItem] (with a `LatLng` anchor)
/// from the framework-free entity. Used ONLY at the region-picker pop boundary,
/// where callers still expect the core type, per the P2.9 boundary rule.
extension ServiceRegionItemEntityMapper on ServiceRegionItemEntity {
  ServiceRegionItem toModel() => ServiceRegionItem(
        region: region,
        regionName: regionName,
        cityId: cityId,
        cityName: cityName,
        anchor: LatLng(anchor.lat, anchor.lng),
        enabled: enabled,
      );
}
