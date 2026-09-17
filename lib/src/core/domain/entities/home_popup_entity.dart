import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// A home popup / overlay descriptor (drives the popup queue).
///
/// [type] selects the renderer: `coupon` | `imageText` | `video` |
/// `verticalBanner` | `newborn`. Every bilingual pair stores the Arabic /
/// default copy in the plain field and the English counterpart in `*En`.
class HomePopupEntity extends Equatable {
  const HomePopupEntity({
    required this.id,
    required this.type,
    this.image = '',
    this.title = '',
    this.titleEn = '',
    this.body = '',
    this.bodyEn = '',
    this.ctaText = '',
    this.ctaTextEn = '',
    this.scheme = '',
    this.amount = '',
    this.amountUnit = '',
    this.amountUnitEn = '',
  });

  final String id;
  final String type;
  final String image;

  /// Arabic / default title.
  final String title;
  final String titleEn;

  /// Arabic / default body.
  final String body;
  final String bodyEn;

  /// Arabic / default CTA label.
  final String ctaText;
  final String ctaTextEn;
  final String scheme;

  /// Voucher amount (coupon popup left panel).
  final String amount;

  /// Arabic / default amount unit (e.g. "د.ك").
  final String amountUnit;

  /// English amount unit (e.g. "KD").
  final String amountUnitEn;

  /// Active-locale title: [title] when `ar*` and non-blank, else [titleEn].
  String titleFor(String languageCode) =>
      pickLocalized(languageCode, en: titleEn, ar: title);

  /// Active-locale body: [body] when `ar*` and non-blank, else [bodyEn].
  String bodyFor(String languageCode) =>
      pickLocalized(languageCode, en: bodyEn, ar: body);

  /// Active-locale CTA: [ctaText] when `ar*` and non-blank, else [ctaTextEn].
  String ctaFor(String languageCode) =>
      pickLocalized(languageCode, en: ctaTextEn, ar: ctaText);

  /// Active-locale amount unit: [amountUnit] when `ar*` and non-blank, else
  /// [amountUnitEn].
  String amountUnitFor(String languageCode) =>
      pickLocalized(languageCode, en: amountUnitEn, ar: amountUnit);

  @override
  List<Object?> get props => [
    id,
    type,
    image,
    title,
    titleEn,
    body,
    bodyEn,
    ctaText,
    ctaTextEn,
    scheme,
    amount,
    amountUnit,
    amountUnitEn,
  ];
}
