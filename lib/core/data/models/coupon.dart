import 'shop.dart' show localizedCatalogName;

/// Marketing coupon model.
class Coupon {
  final String id;
  final String title; // English / default
  final String titleAr; // Arabic counterpart
  final String subtitle; // English / default
  final String subtitleAr; // Arabic counterpart
  final double amount;
  final double minSpend;
  final String expiry;
  final bool used;

  const Coupon({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.subtitle,
    this.subtitleAr = '',
    required this.amount,
    required this.minSpend,
    required this.expiry,
    required this.used,
  });

  /// Locale-aware title / subtitle.
  String get displayTitle => localizedCatalogName(title, titleAr);
  String get displaySubtitle => localizedCatalogName(subtitle, subtitleAr);

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        titleAr: j['titleAr'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        subtitleAr: j['subtitleAr'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        minSpend: (j['minSpend'] as num?)?.toDouble() ?? 0,
        expiry: j['expiry'] as String? ?? '',
        used: j['used'] as bool? ?? false,
      );
}
