import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// One tile in the home horizontal "tiles area" row (`tiles_area`).
///
/// [title] holds the Arabic / default copy, [titleEn] the English counterpart.
class HomeTileEntity extends Equatable {
  const HomeTileEntity({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.image = '',
    this.bg = '#FFFDE0',
    this.scheme = '',
  });

  final String id;

  /// Arabic / default title.
  final String title;

  /// English title.
  final String titleEn;
  final String image;

  /// Hex fallback background when there is no [image].
  final String bg;
  final String scheme;

  /// Active-locale title: [title] when `ar*` and non-blank, else [titleEn].
  String titleFor(String languageCode) =>
      pickLocalized(languageCode, en: titleEn, ar: title);

  @override
  List<Object?> get props => [id, title, titleEn, image, bg, scheme];
}
