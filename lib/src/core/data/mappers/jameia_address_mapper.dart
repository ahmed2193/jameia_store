import '../../domain/entities/jameia_address_entity.dart';
import '../../utils/jameia_geocode.dart' show DropOff, LabelType, StructType;
import '../models/address.dart';

/// `JameiaAddress` DTO ⇄ [JameiaAddressEntity] (lossless both ways).
///
/// The Jameia enums are collapsed to their raw codes on the way in and rebuilt
/// with `fromCode` on the way out, so the domain never imports `jameia_geocode`
/// (and, transitively, `google_maps_flutter`).
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

extension JameiaAddressListMapper on List<JameiaAddress> {
  List<JameiaAddressEntity> toEntities() =>
      map((a) => a.toEntity()).toList(growable: false);
}

/// Reverse map — addresses flow back into `JameiaRepository.upsertAddress`
/// (persisted to local storage via `JameiaAddress.toJson`).
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
