import 'package:equatable/equatable.dart';

import 'product_entity.dart';

/// One rank / sub-category section of a shop menu (rail item + its products).
///
/// [title] is already the resolved section label at build time (the jameia
/// loader writes the rank name), so it has no bilingual counterpart.
class MenuSectionEntity extends Equatable {
  const MenuSectionEntity({
    this.id = '',
    required this.title,
    this.image = '',
    this.products = const [],
  });

  /// Rank / sub-category id ('' for legacy data).
  final String id;
  final String title;

  /// Rank picture ('' → rail shows text-only).
  final String image;
  final List<ProductEntity> products;

  @override
  List<Object?> get props => [id, title, image, products];
}
