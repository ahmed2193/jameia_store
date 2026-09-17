import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'product_entity.dart';

/// A featured menu section = one home product rail ("Offers", "Best sellers",
/// …). [slides] are full banner image URLs; [products] are the rail products.
class FeaturedSectionEntity extends Equatable {
  const FeaturedSectionEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.sorting = 0,
    this.slides = const [],
    this.products = const [],
  });

  final String id;

  /// English / default name.
  final String name;

  /// Arabic name ('' when absent).
  final String nameAr;
  final double sorting;
  final List<String> slides;
  final List<ProductEntity> products;

  /// Active-locale rail title (Arabic when `ar*` and [nameAr] non-blank).
  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: name, ar: nameAr);

  /// Special backend section ids.
  bool get isOrderAgain => id == 'order_again';
  bool get isBestSelling => id == 'best_selling';

  @override
  List<Object?> get props => [id, name, nameAr, sorting, slides, products];
}
