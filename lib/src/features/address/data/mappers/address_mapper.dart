import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/hero_address_entity.dart';
import '../models/address_model.dart';

/// API row → entity. Coordinates become a pin only when both are present.
extension AddressModelMapper on AddressModel {
  HeroAddressEntity toEntity() {
    final latitude = lat;
    final longitude = lng;
    return HeroAddressEntity(
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
  List<HeroAddressEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}

/// Entity → API row, for the device cache (the write path).
extension AddressEntityModelMapper on HeroAddressEntity {
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

extension AddressEntityListModelMapper on List<HeroAddressEntity> {
  List<AddressModel> toModels() =>
      map((address) => address.toModel()).toList(growable: false);
}
