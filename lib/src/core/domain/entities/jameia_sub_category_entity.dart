import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'jameia_rank_entity.dart';
import 'product_entity.dart';

/// A Jameia sub-category = one TAB on the shop (products) page. Has either
/// [ranks] (rank rail + sections) or, when [ranks] is empty, a flat grid of
/// [directProducts].
class JameiaSubCategoryEntity extends Equatable {
  const JameiaSubCategoryEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.image = '',
    this.banner = '',
    this.ranks = const [],
    this.directProducts = const [],
  });

  final String id;

  /// English / default name.
  final String name;

  /// Arabic name ('' when absent).
  final String nameAr;
  final String image;

  /// Optional top-of-tab banner ('' → none).
  final String banner;
  final List<JameiaRankEntity> ranks;

  /// Used only when [ranks] is empty.
  final List<ProductEntity> directProducts;

  /// Active-locale sub-category name (drives the shop sub-tab labels).
  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: name, ar: nameAr);

  bool get hasRanks => ranks.isNotEmpty;

  List<ProductEntity> get allProducts =>
      hasRanks ? [for (final r in ranks) ...r.products] : directProducts;

  @override
  List<Object?> get props => [
    id,
    name,
    nameAr,
    image,
    banner,
    ranks,
    directProducts,
  ];
}
