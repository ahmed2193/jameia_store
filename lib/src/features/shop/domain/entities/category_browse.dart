import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';

/// What the catalogue browser shows: the whole tree, the category the screen
/// is scoped to ([baseSlug] — `null` on the store's own tab) and the
/// descendants the customer picked, nearest first ([path]).
///
/// Every level is one row of choices: level 0 offers the children of the base
/// (the top-level categories when there is no base), level 1 the children of
/// the level-0 pick, and so on. "All" at a level is [path] cut there, so the
/// products below always belong to [activeSlug] — the backend's `categorySlug`
/// filter includes a category's descendants, so a parent row is a real list.
class CategoryBrowse extends Equatable {
  const CategoryBrowse({
    required this.tree,
    this.baseSlug,
    this.base,
    this.path = const <CatalogCategoryEntity>[],
  });

  /// Before the tree arrives; [baseSlug] already scopes the product list.
  CategoryBrowse.initial({String? baseSlug})
    : this(tree: CatalogCategoryTree.empty, baseSlug: baseSlug);

  /// The browse [pathSlugs] describes over [tree]. A slug the tree no longer
  /// has (or that moved under another parent) ends the path there, so a
  /// reload after a catalogue change never shows a row of the wrong category.
  /// [selectFirstOption] picks the first choice of level 0 when nothing is
  /// selected yet — the store tab opens on its first category.
  factory CategoryBrowse.resolve(
    CatalogCategoryTree tree, {
    String? baseSlug,
    List<String> pathSlugs = const <String>[],
    bool selectFirstOption = false,
  }) {
    final base = baseSlug == null ? null : tree.bySlug(baseSlug);
    final path = <CatalogCategoryEntity>[];
    var parentId = base?.id;
    for (final slug in pathSlugs) {
      final category = tree.bySlug(slug);
      if (category == null || category.parentId != parentId) break;
      path.add(category);
      parentId = category.id;
    }
    if (path.isEmpty && selectFirstOption) {
      final options = base == null && baseSlug == null
          ? tree.roots
          : base == null
          ? const <CatalogCategoryEntity>[]
          : tree.childrenOf(base.id);
      if (options.isNotEmpty) path.add(options.first);
    }
    return CategoryBrowse(
      tree: tree,
      baseSlug: baseSlug,
      base: base,
      path: path,
    );
  }

  final CatalogCategoryTree tree;

  /// The category the screen was opened for; `null` browses the whole store.
  final String? baseSlug;

  /// [baseSlug] in the tree — `null` while it loads, or for a slug the tree
  /// does not have (a stale link): the product list still filters by the slug,
  /// there is simply nothing to browse under it.
  final CatalogCategoryEntity? base;

  /// The picked descendants of the base, nearest first.
  final List<CatalogCategoryEntity> path;

  bool get isStoreWide => baseSlug == null;

  /// The deepest pick — what the product list below is filtered by.
  CatalogCategoryEntity? get activeCategory =>
      path.isNotEmpty ? path.last : base;

  /// `null` only while browsing the whole store with nothing picked yet.
  String? get activeSlug => path.isNotEmpty ? path.last.slug : baseSlug;

  List<String> get pathSlugs => <String>[
    for (final category in path) category.slug,
  ];

  /// The parent whose children are offered at [level].
  CatalogCategoryEntity? parentAt(int level) {
    if (level == 0) return base;
    return level <= path.length ? path[level - 1] : null;
  }

  /// The categories to choose from at [level] — empty when the level above has
  /// no pick yet, or when that pick is a leaf.
  List<CatalogCategoryEntity> optionsAt(int level) {
    if (level < 0 || level > path.length) {
      return const <CatalogCategoryEntity>[];
    }
    final parent = parentAt(level);
    if (parent != null) return tree.childrenOf(parent.id);
    return level == 0 && isStoreWide
        ? tree.roots
        : const <CatalogCategoryEntity>[];
  }

  /// What is picked at [level]; `null` is that level's "All".
  CatalogCategoryEntity? selectionAt(int level) =>
      level >= 0 && level < path.length ? path[level] : null;

  /// Pick [category] at [level] (`null` = "All"); every level below is
  /// dropped, because it belonged to the previous pick.
  CategoryBrowse select(int level, CatalogCategoryEntity? category) {
    if (level < 0 || level > path.length) return this;
    return CategoryBrowse(
      tree: tree,
      baseSlug: baseSlug,
      base: base,
      path: <CatalogCategoryEntity>[...path.take(level), ?category],
    );
  }

  @override
  List<Object?> get props => [tree, baseSlug, base, path];
}
