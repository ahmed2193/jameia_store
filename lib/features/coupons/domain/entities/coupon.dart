import 'package:equatable/equatable.dart';

/// Framework-free coupon entity.
///
/// Owned by the coupons feature (no reuse of the core `Coupon` DTO, no
/// `easy_localization` / `intl`). Carries the raw bilingual title/subtitle so
/// the presentation layer can resolve the active-locale display **live** (see
/// `presentation/util/coupon_display.dart`) — a language switch rebuilds the
/// tree, so display text stays correct without reloading the cubit.
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

  /// English / default title + its Arabic counterpart.
  final String title;
  final String titleAr;

  /// English / default subtitle + its Arabic counterpart.
  final String subtitle;
  final String subtitleAr;

  final double amount;
  final double minSpend;
  final String expiry;
  final bool used;

  @override
  List<Object?> get props =>
      [id, title, titleAr, subtitle, subtitleAr, amount, minSpend, expiry, used];
}
