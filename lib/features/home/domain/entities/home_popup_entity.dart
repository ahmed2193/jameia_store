import 'package:equatable/equatable.dart';

/// Framework-free home popup/overlay descriptor entity.
///
/// [type] selects the renderer: `coupon` | `imageText` | `video` |
/// `verticalBanner` | `newborn`. Bilingual fields store Arabic/default plus the
/// English counterpart; the active-locale pick lives in
/// `presentation/util/home_popup_display.dart`.
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
  final String title; // Arabic / default
  final String titleEn; // English counterpart
  final String body; // Arabic / default
  final String bodyEn; // English counterpart
  final String ctaText; // Arabic / default
  final String ctaTextEn; // English counterpart
  final String scheme;
  final String amount;
  final String amountUnit; // Arabic / default
  final String amountUnitEn; // English counterpart

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
