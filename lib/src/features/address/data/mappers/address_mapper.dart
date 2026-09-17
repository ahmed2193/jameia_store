import '../../../../core/data/models/models.dart';
import '../../../../core/utils/jameia_geocode.dart'
    show StructType, LabelType, DropOff;
import '../../domain/entities/jameia_address_entity.dart';

/// DTO ↔ entity mapping for saved addresses. Lives in the data layer, so the
/// framework coupling of the core [JameiaAddress] DTO (it transitively pulls
/// `google_maps_flutter` via `jameia_geocode`) never crosses into the domain
/// [JameiaAddressEntity], which stays plain Dart. The Jameia enums are collapsed
/// to their raw codes on the way in and reconstructed via `fromCode` on the way
/// back out.
extension JameiaAddressMapper on JameiaAddress {
  JameiaAddressEntity toEntity() => JameiaAddressEntity(
    id: id,
    label: label,
    line: line,
    area: area,
    recipient: recipient,
    phone: phone,
    isDefault: isDefault,
    lat: lat,
    lng: lng,
    structTypeCode: structType.code,
    labelTypeCode: labelType.code,
    dropOffLeaveAtSpot: dropOff == DropOff.leaveAtSpot,
    dropSpot: dropSpot,
    altLocation: altLocation,
    poiName: poiName,
    brief: brief,
    detail: detail,
    buildingName: buildingName,
    aptNumber: aptNumber,
    unitOrFloor: unitOrFloor,
    companyName: companyName,
    street: street,
    block: block,
    avenue: avenue,
    additionalDirection: additionalDirection,
    note: note,
  );
}

/// Convenience for mapping the whole list.
extension JameiaAddressListMapper on List<JameiaAddress> {
  List<JameiaAddressEntity> toEntities() => map((a) => a.toEntity()).toList();
}

/// Reverse map — rebuild the persistable core [JameiaAddress] from the
/// framework-free entity. Used ONLY at feature boundaries where the entity must
/// be handed back as the core type (the list picker pop / edit deep-link),
/// per the P2.9 boundary rule.
extension JameiaAddressEntityMapper on JameiaAddressEntity {
  JameiaAddress toModel() => JameiaAddress(
    id: id,
    label: label,
    line: line,
    area: area,
    recipient: recipient,
    phone: phone,
    isDefault: isDefault,
    lat: lat,
    lng: lng,
    structType: StructType.fromCode(structTypeCode),
    labelType: LabelType.fromCode(labelTypeCode),
    dropOff: dropOffLeaveAtSpot ? DropOff.leaveAtSpot : DropOff.handToMe,
    dropSpot: dropSpot,
    altLocation: altLocation,
    poiName: poiName,
    brief: brief,
    detail: detail,
    buildingName: buildingName,
    aptNumber: aptNumber,
    unitOrFloor: unitOrFloor,
    companyName: companyName,
    street: street,
    block: block,
    avenue: avenue,
    additionalDirection: additionalDirection,
    note: note,
  );
}
