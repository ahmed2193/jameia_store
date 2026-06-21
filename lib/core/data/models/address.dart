/// Delivery address model.
class KeetaAddress {
  final String id;
  final String label; // Home | Office | Other
  final String line;
  final String area;
  final String recipient;
  final String phone;
  final bool isDefault;
  final double lat;
  final double lng;

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
  });

  String get fullText => '$line, $area';

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
      );
}
