import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'product_entity.dart';

/// One rank inside a Jameia sub-category — the unit of the shop page's rank
/// rail (rail item + section of products).
class JameiaRankEntity extends Equatable {
  const JameiaRankEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.image = '',
    this.count = 0,
    this.products = const [],
  });

  final String id;

  /// English / default name.
  final String name;

  /// Arabic name ('' when absent).
  final String nameAr;

  /// Rank thumbnail ('' → rail shows text-only).
  final String image;

  /// Backend product count.
  final int count;
  final List<ProductEntity> products;

  /// Active-locale rank name (Arabic when `ar*` and [nameAr] non-blank).
  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: name, ar: nameAr);

  @override
  List<Object?> get props => [id, name, nameAr, image, count, products];
}
