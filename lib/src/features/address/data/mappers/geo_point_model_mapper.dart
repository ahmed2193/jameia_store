import '../../../../core/domain/entities/geo_point_entity.dart';
import '../models/geo_point_model.dart';

extension GeoPointModelMapper on GeoPointModel {
  GeoPointEntity toEntity() => GeoPointEntity(lat: lat, lng: lng);
}

extension GeoPointEntityModelMapper on GeoPointEntity {
  GeoPointModel toModel() => GeoPointModel(lat: lat, lng: lng);
}
