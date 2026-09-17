import 'package:equatable/equatable.dart';

/// Saved delivery address (address book, home address bar, checkout address
/// bar, order tracking map).
///
/// Carries every raw field of the `JameiaAddress` DTO. The Jameia enums are
/// stored as their raw codes so the domain imports nothing from
/// `core/utils/jameia_geocode.dart` (which pulls `google_maps_flutter`):
/// - [structTypeCode] == `StructType.code` (2 apartment · 3 house · 4 office)
/// - [labelTypeCode] == `LabelType.code` (0 home … 5 other)
/// - [dropOffLeaveAtSpot] == `DropOff.leaveAtSpot` (false → `handToMe`)
///
/// Presentation rebuilds the enums with `StructType.fromCode(...)` /
/// `LabelType.fromCode(...)`. Defaults mirror `JameiaAddress.fromJson`.
class JameiaAddressEntity extends Equatable {
  const JameiaAddressEntity({
    required this.id,
    required this.label,
    this.line = '',
    this.area = '',
    this.recipient = '',
    this.phone = '',
    this.isDefault = false,
    this.lat = 0,
    this.lng = 0,
    this.structTypeCode = 2,
    this.labelTypeCode = 0,
    this.dropOffLeaveAtSpot = false,
    this.dropSpot = '',
    this.altLocation = '',
    this.poiName = '',
    this.brief = '',
    this.detail = '',
    this.buildingName = '',
    this.aptNumber = '',
    this.unitOrFloor = '',
    this.companyName = '',
    this.street = '',
    this.block = '',
    this.avenue = '',
    this.additionalDirection = '',
    this.note = '',
  });

  final String id;

  /// Tag display: Home | Work | Hangout | Other.
  final String label;

  /// Legacy one-line address (== detail/brief fallback).
  final String line;
  final String area;
  final String recipient;
  final String phone;
  final bool isDefault;
  final double lat;
  final double lng;

  /// `StructType.code` (2 apartment · 3 house · 4 office).
  final int structTypeCode;

  /// `LabelType.code` (0 home · 1 work · 2 hangout · 3 faceDelivery ·
  /// 4 assignedPlace · 5 other).
  final int labelTypeCode;

  /// `DropOff.leaveAtSpot` when true, `DropOff.handToMe` when false.
  final bool dropOffLeaveAtSpot;

  /// frontDoor | lobby | frontDesk | other | ''.
  final String dropSpot;
  final String altLocation;
  final String poiName;
  final String brief;
  final String detail;
  final String buildingName;
  final String aptNumber;
  final String unitOrFloor;
  final String companyName;
  final String street;
  final String block;
  final String avenue;
  final String additionalDirection;
  final String note;

  /// Two-line display: the brief line (or legacy [line]) + area.
  String get fullText {
    final head = brief.isNotEmpty ? brief : line;
    return area.isEmpty ? head : '$head, $area';
  }

  /// Home-bar / picker headline. Prefers an explicit POI name, else the brief.
  String get displayTitle {
    if (poiName.isNotEmpty) return poiName;
    if (brief.isNotEmpty) return brief;
    return line.isNotEmpty ? line : area;
  }

  @override
  List<Object?> get props => [
    id,
    label,
    line,
    area,
    recipient,
    phone,
    isDefault,
    lat,
    lng,
    structTypeCode,
    labelTypeCode,
    dropOffLeaveAtSpot,
    dropSpot,
    altLocation,
    poiName,
    brief,
    detail,
    buildingName,
    aptNumber,
    unitOrFloor,
    companyName,
    street,
    block,
    avenue,
    additionalDirection,
    note,
  ];
}
