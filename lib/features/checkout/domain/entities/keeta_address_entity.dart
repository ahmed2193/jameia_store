import 'package:equatable/equatable.dart';

/// Framework-free delivery-address entity for the checkout feature.
///
/// Carries only the fields the checkout address bar renders (type label,
/// composed two-line text, recipient + phone). The two-line [fullText] is a
/// pure string join (no locale), so it stays on the entity rather than a
/// presentation display extension.
class KeetaAddressEntity extends Equatable {
  const KeetaAddressEntity({
    required this.id,
    required this.label,
    required this.brief,
    required this.line,
    required this.area,
    required this.recipient,
    required this.phone,
  });

  /// Tag display: Home | Work | Hangout | Other.
  final String label;
  final String id;

  /// Composed brief line + legacy one-line fallback + area (feed [fullText]).
  final String brief;
  final String line;
  final String area;

  final String recipient;
  final String phone;

  /// Two-line display: the brief line (or legacy [line]) + area — mirrors the
  /// core `KeetaAddress.fullText` getter exactly (pure Dart, no locale).
  String get fullText {
    final head = brief.isNotEmpty ? brief : line;
    return area.isEmpty ? head : '$head, $area';
  }

  @override
  List<Object?> get props => [id, label, brief, line, area, recipient, phone];
}
