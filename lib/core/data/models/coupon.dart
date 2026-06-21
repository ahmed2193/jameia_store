/// Marketing coupon model.
class Coupon {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final double minSpend;
  final String expiry;
  final bool used;

  const Coupon({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.minSpend,
    required this.expiry,
    required this.used,
  });

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        minSpend: (j['minSpend'] as num?)?.toDouble() ?? 0,
        expiry: j['expiry'] as String? ?? '',
        used: j['used'] as bool? ?? false,
      );
}
