import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'jameia_sub_category_entity.dart';
import 'product_entity.dart';

/// A top-level Jameia category = a "shop" entry point on home; opens the shop
/// page where its [subs] become the tabs.
///
/// [subs] is empty when mapped as a summary (home "Shop by category" rail only
/// needs id / artwork / name) — see `JameiaCategoryMapper.toSummaryEntity`.
class JameiaCategoryEntity extends Equatable {
  const JameiaCategoryEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.image = '',
    this.subs = const [],
  });

  final String id;

  /// English / default name.
  final String name;

  /// Arabic name ('' when absent).
  final String nameAr;
  final String image;
  final List<JameiaSubCategoryEntity> subs;

  /// Active-locale category name (home category rail / shop title).
  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: name, ar: nameAr);

  List<ProductEntity> get allProducts => [
    for (final s in subs) ...s.allProducts,
  ];

  @override
  List<Object?> get props => [id, name, nameAr, image, subs];
}
