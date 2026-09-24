import 'package:equatable/equatable.dart';

/// A category of the jm3eia backend catalogue. The backend sends the tree
/// flat, linked by [parentId] (three levels today: `Fresh Food` →
/// `Fruits & Vegetables` → `Apples`); [CatalogCategoryTree] rebuilds it.
///
/// [slug] is what the product list filters by (`categorySlug`); a parent's
/// listing includes the products of its descendants. [name] arrives already
/// resolved for the request language.
class CatalogCategoryEntity extends Equatable {
  const CatalogCategoryEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.image = '',
    this.parentId,
    this.sortOrder = 0,
    this.productCount = 0,
  });

  final String id;
  final String slug;
  final String name;
  final String image;

  /// `null` for a top-level category.
  final String? parentId;
  final int sortOrder;

  /// A backend counter, not a promise: never hide a category because of it.
  final int productCount;

  bool get isRoot => parentId == null;
  bool get hasImage => image.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    image,
    parentId,
    sortOrder,
    productCount,
  ];
}

/// The category tree rebuilt from the flat backend list. Siblings keep the
/// backend order ([CatalogCategoryEntity.sortOrder], then the wire order).
class CatalogCategoryTree extends Equatable {
  CatalogCategoryTree(List<CatalogCategoryEntity> categories)
    : all = List<CatalogCategoryEntity>.unmodifiable(_sorted(categories));

  static final CatalogCategoryTree empty = CatalogCategoryTree(
    const <CatalogCategoryEntity>[],
  );

  /// Every category, siblings in display order.
  final List<CatalogCategoryEntity> all;

  bool get isEmpty => all.isEmpty;

  /// Top-level categories. A row whose parent is missing from the list is
  /// treated as a root, so a partial tree never hides it.
  List<CatalogCategoryEntity> get roots {
    final ids = {for (final category in all) category.id};
    return [
      for (final category in all)
        if (category.isRoot || !ids.contains(category.parentId)) category,
    ];
  }

  List<CatalogCategoryEntity> childrenOf(String categoryId) => [
    for (final category in all)
      if (category.parentId == categoryId) category,
  ];

  CatalogCategoryEntity? bySlug(String slug) {
    for (final category in all) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  static List<CatalogCategoryEntity> _sorted(
    List<CatalogCategoryEntity> categories,
  ) {
    final indexed = categories.indexed.toList()
      ..sort((a, b) {
        final bySort = a.$2.sortOrder.compareTo(b.$2.sortOrder);
        return bySort != 0 ? bySort : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }

  @override
  List<Object?> get props => [all];
}
