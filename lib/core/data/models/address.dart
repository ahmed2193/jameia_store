import '../../utils/keeta_geocode.dart';

/// Delivery address model.
///
/// Carries both the legacy flat fields (`label`/`line`/`area`) AND the
/// schema-driven KeeTa fields (structType, labelType, dropOff, composed
/// brief/detail lines, recipient + per-struct address parts). New fields default
/// so the bundled `keeta_data.json` (flat shape) still parses.
class KeetaAddress {
  final String id;
  final String label; // tag display: Home | Work | Hangout | Other
  final String line; // legacy one-line address (== detail/brief fallback)
  final String area;
  final String recipient;
  final String phone;
  final bool isDefault;
  final double lat;
  final double lng;

  // ── Schema-driven fields (KeeTa parity) ─────────────────────────────────────
  final StructType structType;
  final LabelType labelType;
  final DropOff dropOff;
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

  const KeetaAddress({
    required this.id,
    required this.label,
    required this.line,
    required this.area,
    required this.recipient,
    required this.phone,
    required this.isDefault,
    required this.lat,
    required this.lng,
    this.structType = StructType.apartment,
    this.labelType = LabelType.home,
    this.dropOff = DropOff.handToMe,
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

  /// A benign empty placeholder returned by the default/active-address getters
  /// when the address book is somehow empty — so they never throw. Not shown in
  /// normal use (the book is seeded non-empty and delete keeps the last row);
  /// coordinates default to the Kuwait City base so any map stays sane.
  static final KeetaAddress empty = KeetaAddress(
    id: '',
    label: '',
    line: '',
    area: '',
    recipient: '',
    phone: '',
    isDefault: false,
    lat: KeetaGeocode.base.latitude,
    lng: KeetaGeocode.base.longitude,
  );

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

  KeetaAddress copyWith({
    String? id,
    String? label,
    String? line,
    String? area,
    String? recipient,
    String? phone,
    bool? isDefault,
    double? lat,
    double? lng,
    StructType? structType,
    LabelType? labelType,
    DropOff? dropOff,
    String? dropSpot,
    String? altLocation,
    String? poiName,
    String? brief,
    String? detail,
    String? buildingName,
    String? aptNumber,
    String? unitOrFloor,
    String? companyName,
    String? street,
    String? block,
    String? avenue,
    String? additionalDirection,
    String? note,
  }) =>
      KeetaAddress(
        id: id ?? this.id,
        label: label ?? this.label,
        line: line ?? this.line,
        area: area ?? this.area,
        recipient: recipient ?? this.recipient,
        phone: phone ?? this.phone,
        isDefault: isDefault ?? this.isDefault,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        structType: structType ?? this.structType,
        labelType: labelType ?? this.labelType,
        dropOff: dropOff ?? this.dropOff,
        dropSpot: dropSpot ?? this.dropSpot,
        altLocation: altLocation ?? this.altLocation,
        poiName: poiName ?? this.poiName,
        brief: brief ?? this.brief,
        detail: detail ?? this.detail,
        buildingName: buildingName ?? this.buildingName,
        aptNumber: aptNumber ?? this.aptNumber,
        unitOrFloor: unitOrFloor ?? this.unitOrFloor,
        companyName: companyName ?? this.companyName,
        street: street ?? this.street,
        block: block ?? this.block,
        avenue: avenue ?? this.avenue,
        additionalDirection: additionalDirection ?? this.additionalDirection,
        note: note ?? this.note,
      );

  factory KeetaAddress.fromJson(Map<String, dynamic> j) => KeetaAddress(
        id: j['id'] as String,
        label: j['label'] as String? ?? 'Home',
        line: j['line'] as String? ?? '',
        area: j['area'] as String? ?? '',
        recipient: j['recipient'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        isDefault: j['isDefault'] as bool? ?? false,
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        structType: StructType.fromCode((j['structType'] as num?)?.toInt() ?? 2),
        labelType: LabelType.fromCode((j['labelType'] as num?)?.toInt() ?? 0),
        dropOff: (j['dropOff'] as String?) == 'leaveAtSpot'
            ? DropOff.leaveAtSpot
            : DropOff.handToMe,
        dropSpot: j['dropSpot'] as String? ?? '',
        altLocation: j['altLocation'] as String? ?? '',
        poiName: j['poiName'] as String? ?? '',
        brief: j['brief'] as String? ?? '',
        detail: j['detail'] as String? ?? '',
        buildingName: j['buildingName'] as String? ?? '',
        aptNumber: j['aptNumber'] as String? ?? '',
        unitOrFloor: j['unitOrFloor'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        street: j['street'] as String? ?? '',
        block: j['block'] as String? ?? '',
        avenue: j['avenue'] as String? ?? '',
        additionalDirection: j['additionalDirection'] as String? ?? '',
        note: j['note'] as String? ?? '',
      );

  /// Serializes back to the `keeta_data.json` address shape — used to persist
  /// user-added/edited addresses to local storage (shared_preferences).
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'line': line,
        'area': area,
        'recipient': recipient,
        'phone': phone,
        'isDefault': isDefault,
        'lat': lat,
        'lng': lng,
        'structType': structType.code,
        'labelType': labelType.code,
        'dropOff': dropOff == DropOff.leaveAtSpot ? 'leaveAtSpot' : 'handToMe',
        'dropSpot': dropSpot,
        'altLocation': altLocation,
        'poiName': poiName,
        'brief': brief,
        'detail': detail,
        'buildingName': buildingName,
        'aptNumber': aptNumber,
        'unitOrFloor': unitOrFloor,
        'companyName': companyName,
        'street': street,
        'block': block,
        'avenue': avenue,
        'additionalDirection': additionalDirection,
        'note': note,
      };
}
