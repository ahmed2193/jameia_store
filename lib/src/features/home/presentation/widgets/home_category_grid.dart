import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/widgets/paging_dots.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_category_tile.dart';
import 'home_section_block.dart';

/// "Shop by category": the store's categories as a horizontally paged grid
/// with paging dots — the whole shelf at a glance instead of a rail the
/// customer has to drag through. "View all" opens the full tree.
class HomeCategoryGrid extends StatefulWidget {
  const HomeCategoryGrid({
    super.key,
    required this.section,
    required this.onOpenCategory,
    required this.onViewAll,
  });

  final HomeCategoryRailSection section;
  final ValueChanged<CatalogCategoryEntity> onOpenCategory;
  final VoidCallback onViewAll;

  @override
  State<HomeCategoryGrid> createState() => _HomeCategoryGridState();
}

class _HomeCategoryGridState extends State<HomeCategoryGrid>
    with AutomaticKeepAliveClientMixin {
  static const int _maxRows = 3;
  static const int _columns = 4;
  static const int _perPage = _maxRows * _columns;

  /// The next page peeks, exactly like the hero carousel.
  static const double _viewportFraction = 0.94;
  static const double _pageGutter = AppSpacing.s4;

  final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
  );

  /// The feed is a lazy sliver list: without this the element is recycled
  /// once the grid scrolls out of the cache, the controller is disposed and
  /// the customer comes back to page 1.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categories = widget.section.categories;
    if (categories.isEmpty) return const SizedBox.shrink();
    final pages = (categories.length / _perPage).ceil();
    // Every page but the last is full, so the tallest page is what the rows
    // of the first page need.
    final rows = math.min(_maxRows, (categories.length / _columns).ceil());
    final pageHeight =
        HomeCategoryTile.height * rows + AppSpacing.s8 * (rows - 1);
    return HomeSectionBlock(
      section: widget.section,
      onSeeAll: widget.onViewAll,
      child: Column(
        children: [
          SizedBox(
            height: pageHeight,
            child: PageView.builder(
              controller: _controller,
              itemCount: pages,
              itemBuilder: (context, page) {
                final start = page * _perPage;
                final end = math.min(start + _perPage, categories.length);
                final slice = categories.sublist(start, end);
                return Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: _pageGutter,
                  ),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columns,
                          mainAxisSpacing: AppSpacing.s8,
                          crossAxisSpacing: AppSpacing.s8,
                          mainAxisExtent: HomeCategoryTile.height,
                        ),
                    itemCount: slice.length,
                    itemBuilder: (context, index) => HomeCategoryTile(
                      key: ValueKey<String>(slice[index].id),
                      category: slice[index],
                      onTap: () => widget.onOpenCategory(slice[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          if (pages > 1)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.s10),
              child: PagingDots(controller: _controller, count: pages),
            ),
        ],
      ),
    );
  }
}
