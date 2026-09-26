import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';

enum ListingTabsStatus { initial, loading, loaded, failed }

/// The category tabs of a collection page: tab 0 is "All", then one tab per
/// top-level category the list has products in ([categories]).
class ListingTabsState extends Equatable {
  const ListingTabsState({
    this.status = ListingTabsStatus.initial,
    this.categories = const <CatalogCategoryEntity>[],
  });

  /// Fewer categories than this and the list is not worth splitting: no tabs.
  static const int minCategories = 2;

  /// Position of the "All" tab.
  static const int allTab = 0;

  final ListingTabsStatus status;

  /// Kept while a reload runs (a language switch), empty after a failure.
  final List<CatalogCategoryEntity> categories;

  bool get showsTabs => categories.length >= minCategories;

  /// The tab of the list scoped to [categorySlug] (`null` = "All"). A slug
  /// with no tab reads as "All".
  int tabOf(String? categorySlug) {
    if (categorySlug == null) return allTab;
    for (var i = 0; i < categories.length; i++) {
      if (categories[i].slug == categorySlug) return i + 1;
    }
    return allTab;
  }

  /// The category slug tab [index] scopes the list to; `null` for "All".
  String? slugAt(int index) => index <= allTab || index > categories.length
      ? null
      : categories[index - 1].slug;

  /// Whether the tabs on screen can show the list scoped to [categorySlug].
  bool hasTabFor(String? categorySlug) =>
      categorySlug == null ||
      (showsTabs && categories.any((c) => c.slug == categorySlug));

  ListingTabsState copyWith({
    ListingTabsStatus? status,
    List<CatalogCategoryEntity>? categories,
  }) => ListingTabsState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
  );

  @override
  List<Object?> get props => [status, categories];
}
