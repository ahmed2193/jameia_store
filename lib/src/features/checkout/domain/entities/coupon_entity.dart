import 'package:equatable/equatable.dart';

/// Framework-free coupon entity, **owned by the checkout feature**.
///
/// Independent of the coupons feature's own `CouponEntity` (parallel rewrite):
/// checkout drives its own money math (discount gate) off [amount] / [minSpend],
/// and carries the raw bilingual title/subtitle so any later display resolves
/// live off the raw fields — never freezing a locale in the entity.
class CouponEntity extends Equatable {
  const CouponEntity({
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

  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final double amount;
  final double minSpend;
  final String expiry;
  final bool used;

  @override
  List<Object?> get props => [
    id,
    title,
    titleAr,
    subtitle,
    subtitleAr,
    amount,
    minSpend,
    expiry,
    used,
  ];
}
