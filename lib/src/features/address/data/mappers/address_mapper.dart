import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../models/address_model.dart';

/// API row → entity. Coordinates become a pin only when both are present.
extension AddressModelMapper on AddressModel {
  JameiaAddressEntity toEntity() {
    final latitude = lat;
    final longitude = lng;
    return JameiaAddressEntity(
      id: id,
      label: label,
      city: city,
      governorateNo: governorateNo,
      areaId: areaId,
      block: block,
      street: street,
      building: building,
      floor: floor,
      apartment: apartment,
      phone: phone,
      notes: notes,
      location: latitude == null || longitude == null
          ? null
          : GeoPointEntity(lat: latitude, lng: longitude),
      isDefault: isDefault,
    );
  }
}

extension AddressModelListMapper on List<AddressModel> {
  List<JameiaAddressEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}

/// Entity → API row, for the device cache (the write path).
extension AddressEntityModelMapper on JameiaAddressEntity {
  AddressModel toModel() => AddressModel(
    id: id,
    label: label,
    city: city,
    governorateNo: governorateNo,
    areaId: areaId,
    block: block,
    street: street,
    building: building,
    floor: floor,
    apartment: apartment,
    phone: phone,
    notes: notes,
    lat: location?.lat,
    lng: location?.lng,
    isDefault: isDefault,
  );
}

extension AddressEntityListModelMapper on List<JameiaAddressEntity> {
  List<AddressModel> toModels() =>
      map((address) => address.toModel()).toList(growable: false);
}
