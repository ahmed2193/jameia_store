import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// One slide of the home banner carousel.
///
/// [title] is the English / default title, [titleAr] its Arabic counterpart.
/// When [itemCount] > 0 the carousel renders a localized "{n} items" subtitle;
/// otherwise the raw [subtitle] (fallback JSON banners).
class HomeBannerEntity extends Equatable {
  const HomeBannerEntity({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.subtitle,
    this.itemCount = 0,
    required this.image,
    required this.bg,
  });

  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final int itemCount;
  final String image;

  /// Background hex colour.
  final String bg;

  /// Active-locale title (Arabic when `ar*` and [titleAr] non-blank).
  String titleFor(String languageCode) =>
      pickLocalized(languageCode, en: title, ar: titleAr);

  @override
  List<Object?> get props => [
    id,
    title,
    titleAr,
    subtitle,
    itemCount,
    image,
    bg,
  ];
}
