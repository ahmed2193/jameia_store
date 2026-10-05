import '../../domain/entities/service_area.dart';
import '../models/service_area_model.dart';
import 'geo_point_model_mapper.dart';

extension ServiceAreaMapper on ServiceAreaModel {
  ServiceArea toEntity() => ServiceArea([
    for (final ring in rings) [for (final corner in ring) corner.toEntity()],
  ]);
}
