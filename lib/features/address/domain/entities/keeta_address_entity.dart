import 'package:equatable/equatable.dart';

/// Framework-free saved-address entity.
///
/// Owned by the address feature (no reuse of the core `KeetaAddress` DTO, which
/// transitively pulls `google_maps_flutter` through `keeta_geocode`). Carries
/// every raw field the DTO does, but stores the KeeTa enums as their raw INT /
/// bool codes so it imports nothing from `core/*` — the data-layer mapper
/// reconstructs `StructType` / `LabelType` / `DropOff` via their `fromCode`
/// factories (see `data/mappers/address_mapper.dart`).
///
/// The two display getters ([fullText] / [displayTitle]) are pure string logic
/// (no `.tr()` / locale), so they live on the entity directly — unlike the
/// coupon feature's locale-live display, which had to move to a presentation
/// extension.
class KeetaAddressEntity extends Equatable {
  const KeetaAddressEntity({
    required this.id,
    required this.label,
    required this.line,
    required this.area,
    required this.recipient,
    required this.phone,
    required this.isDefault,
    required this.lat,
    required this.lng,
    required this.structTypeCode,
    required this.labelTypeCode,
    required this.dropOffLeaveAtSpot,
    required this.dropSpot,
    required this.altLocation,
    required this.poiName,
    required this.brief,
    required this.detail,
    required this.buildingName,
    required this.aptNumber,
    required this.unitOrFloor,
    required this.companyName,
    required this.street,
    required this.block,
    required this.avenue,
    required this.additionalDirection,
    required this.note,
  });

  final String id;
  final String label; // tag display: Home | Work | Hangout | Other
  final String line; // legacy one-line address (== detail/brief fallback)
  final String area;
  final String recipient;
  final String phone;
  final bool isDefault;
  final double lat;
  final double lng;

  // KeeTa enums carried as their raw codes (framework-free).
  final int structTypeCode; // StructType.code (2 apt / 3 house / 4 office)
  final int labelTypeCode; // LabelType.code (0 home … 5 other)
  final bool dropOffLeaveAtSpot; // DropOff.leaveAtSpot vs handToMe

  final String dropSpot; // frontDoor | lobby | frontDesk | other | ''
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
