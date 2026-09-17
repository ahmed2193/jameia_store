import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// One tile of the home KingKong entry grid (category shortcut).
///
/// [title] is the English / default label, [titleAr] its Arabic counterpart.
/// [icon] is a material icon name (mapped in the widget) used when there is no
/// [image]; [color] stays a raw hex string.
class KingKongItemEntity extends Equatable {
  const KingKongItemEntity({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.icon,
    required this.color,
    this.image = '',
  });

  final String id;
  final String title;
  final String titleAr;
  final String icon;
  final String color;
  final String image;

  /// Active-locale title (Arabic when `ar*` and [titleAr] non-blank).
  String titleFor(String languageCode) =>
      pickLocalized(languageCode, en: title, ar: titleAr);

  bool get hasImage => image.isNotEmpty;

  @override
  List<Object?> get props => [id, title, titleAr, icon, color, image];
}
