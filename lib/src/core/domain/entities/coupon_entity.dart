import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// Marketing / order coupon (coupon wallet tabs, checkout coupon picker and
/// discount math).
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

  /// English / default title.
  final String title;

  /// Arabic title ('' when absent).
  final String titleAr;

  /// English / default subtitle.
  final String subtitle;

  /// Arabic subtitle ('' when absent).
  final String subtitleAr;

  /// Flat discount amount (KD).
  final double amount;

  /// Minimum cart subtotal for the coupon to apply.
  final double minSpend;
  final String expiry;
  final bool used;

  /// Active-locale title (Arabic when `ar*` and non-blank).
  String titleFor(String languageCode) =>
      pickLocalized(languageCode, en: title, ar: titleAr);

  /// Active-locale subtitle (Arabic when `ar*` and non-blank).
  String subtitleFor(String languageCode) =>
      pickLocalized(languageCode, en: subtitle, ar: subtitleAr);

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
