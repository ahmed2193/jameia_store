import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/known_area.dart';
import '../models/known_area_model.dart';

extension KnownAreaMapper on KnownAreaModel {
  KnownArea toEntity() => KnownArea(
    id: id,
    nameEn: nameEn,
    nameAr: nameAr,
    location: GeoPointEntity(lat: lat, lng: lng),
    governorateEn: governorateEn,
    governorateAr: governorateAr,
  );
}

extension KnownAreaListMapper on List<KnownAreaModel> {
  List<KnownArea> toEntities() => [for (final area in this) area.toEntity()];
}
