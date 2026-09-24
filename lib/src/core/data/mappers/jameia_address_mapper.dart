import '../../domain/entities/geo_point_entity.dart';
import '../../domain/entities/jameia_address_entity.dart';
import '../models/address.dart';

/// Offline catalogue `JameiaAddress` DTO → the API-shaped
/// [JameiaAddressEntity].
///
/// One way only: the address book now lives on the API, so nothing writes an
/// entity back into the offline catalogue. Fields the API has no slot for
/// (recipient, struct type, drop-off, avenue …) are dropped; the rest map to
/// their API names (`area` → `city`, `buildingName` → `building`,
/// `unitOrFloor` → `floor`, `aptNumber` → `apartment`, `note` → `notes`).
extension JameiaAddressMapper on JameiaAddress {
  JameiaAddressEntity toEntity() => JameiaAddressEntity(
    id: id,
    label: label,
    city: area,
    block: block,
    street: street,
    building: buildingName,
    floor: unitOrFloor,
    apartment: aptNumber,
    phone: phone,
    notes: note,
    location: GeoPointEntity(lat: lat, lng: lng),
    isDefault: isDefault,
  );
}

extension JameiaAddressListMapper on List<JameiaAddress> {
  List<JameiaAddressEntity> toEntities() =>
      map((a) => a.toEntity()).toList(growable: false);
}
