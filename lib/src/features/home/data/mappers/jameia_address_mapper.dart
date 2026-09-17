import '../../../../core/data/models/models.dart';
import '../../domain/entities/jameia_address_entity.dart';

/// DTO → entity mapping for the home address bar. Carries only the display fields
/// the home surface shows (tag / area / brief / POI) plus the coordinates.
extension JameiaAddressMapper on JameiaAddress {
  JameiaAddressEntity toEntity() => JameiaAddressEntity(
    id: id,
    label: label,
    line: line,
    area: area,
    poiName: poiName,
    brief: brief,
    detail: detail,
    recipient: recipient,
    phone: phone,
    lat: lat,
    lng: lng,
  );
}
