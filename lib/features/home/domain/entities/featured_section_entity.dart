import 'package:equatable/equatable.dart';

import 'product_entity.dart';

/// Framework-free featured-section entity — one home product rail.
///
/// Owned by the home feature (no reuse of the core `FeaturedSection` DTO). The
/// special-section flags (`isOrderAgain`, `isBestSelling`) are pure derivations
/// on the raw id; locale-live name resolution lives in
/// `presentation/util/featured_section_display.dart`.
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
  final String name;
  final String nameAr;
  final double sorting;
  final List<String> slides;
  final List<ProductEntity> products;

  bool get isOrderAgain => id == 'order_again';
  bool get isBestSelling => id == 'best_selling';

  @override
  List<Object?> get props => [id, name, nameAr, sorting, slides, products];
}
