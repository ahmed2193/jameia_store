import 'package:equatable/equatable.dart';

/// Framework-free delivery-address entity for the orders feature (no reuse of
/// the core `JameiaAddress` DTO). Carries only the raw fields the tracking / map
/// screens render — the delivery headline, recipient contact, and coordinates.
///
/// `fullText` / `displayTitle` are pure string composition (no `.tr()` /
/// locale), so they stay on the entity rather than a display extension.
class OrderAddressEntity extends Equatable {
  const OrderAddressEntity({
    required this.id,
    required this.label,
    this.line = '',
    this.area = '',
    this.recipient = '',
    this.phone = '',
    this.poiName = '',
    this.brief = '',
    this.lat = 0,
    this.lng = 0,
  });

  final String id;
  final String label; // tag display: Home | Work | Hangout | Other
  final String line; // legacy one-line address (brief/detail fallback)
  final String area;
  final String recipient;
  final String phone;
  final String poiName;
  final String brief;
  final double lat;
  final double lng;

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
    poiName,
    brief,
    lat,
    lng,
  ];
}
