import 'package:equatable/equatable.dart';

/// Framework-free delivery-address entity for the home address bar.
///
/// The home surface only shows the tag ([label]) + [area] (and the pure
/// [displayTitle] / [fullText] headlines), so the entity carries those display
/// fields plus the coordinates. No locale-live getters — the address strings are
/// user data, not translated.
class JameiaAddressEntity extends Equatable {
  const JameiaAddressEntity({
    required this.id,
    required this.label,
    required this.line,
    required this.area,
    this.poiName = '',
    this.brief = '',
    this.detail = '',
    this.recipient = '',
    this.phone = '',
    this.lat = 0,
    this.lng = 0,
  });

  final String id;
  final String label; // tag display: Home | Work | Hangout | Other
  final String line; // legacy one-line address
  final String area;
  final String poiName;
  final String brief;
  final String detail;
  final String recipient;
  final String phone;
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
    poiName,
    brief,
    detail,
    recipient,
    phone,
    lat,
    lng,
  ];
}
