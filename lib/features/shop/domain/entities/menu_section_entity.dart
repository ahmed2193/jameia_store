import 'package:equatable/equatable.dart';

import 'product_entity.dart';

/// Framework-free menu-section entity — one rank / sub-category section on the
/// shop menu (rail item + its product list). Owned by the shop feature (no reuse
/// of the core `MenuSection` DTO). [title] is already the resolved rank label at
/// mapping time, so it needs no live locale resolution.
class MenuSectionEntity extends Equatable {
  const MenuSectionEntity({
    this.id = '',
    required this.title,
    this.image = '',
    required this.products,
  });

  /// Rank / subcategory id ('' for legacy data).
  final String id;
  final String title;

  /// Rank picture ('' → rail shows text-only).
  final String image;
  final List<ProductEntity> products;

  @override
  List<Object?> get props => [id, title, image, products];
}
