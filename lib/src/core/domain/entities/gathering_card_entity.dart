import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// One card in the home "gathering" carousel (`gathering_card_v3`).
///
/// NOTE the inverted source convention: [title] / [subtitle] hold the Arabic /
/// default copy and [titleEn] / [subtitleEn] the English counterpart.
class GatheringCardEntity extends Equatable {
  const GatheringCardEntity({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.subtitle = '',
    this.subtitleEn = '',
    this.image = '',
    this.price = 0,
    this.scheme = '',
  });

  final String id;

  /// Arabic / default title.
  final String title;

  /// English title.
  final String titleEn;

  /// Arabic / default subtitle.
  final String subtitle;

  /// English subtitle.
  final String subtitleEn;
  final String image;

  /// 0 == hide price.
  final double price;

  /// Deep-link target id (shop/channel).
  final String scheme;

  /// Active-locale title: [title] when `ar*` and non-blank, else [titleEn].
  String titleFor(String languageCode) =>
      pickLocalized(languageCode, en: titleEn, ar: title);

  /// Active-locale subtitle: [subtitle] when `ar*` and non-blank, else
  /// [subtitleEn].
  String subtitleFor(String languageCode) =>
      pickLocalized(languageCode, en: subtitleEn, ar: subtitle);

  @override
  List<Object?> get props => [
    id,
    title,
    titleEn,
    subtitle,
    subtitleEn,
    image,
    price,
    scheme,
  ];
}
