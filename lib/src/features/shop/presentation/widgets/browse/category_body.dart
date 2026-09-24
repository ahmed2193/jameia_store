import 'package:flutter/material.dart';

import '../listing/product_listing_body.dart';
import 'category_chips.dart';
import 'category_rail.dart';

/// Body of a category page: the sub-category rail, its chips and the products
/// of whatever is picked. The product list is scoped by the slug the page was
/// opened with, so it never waits for the category tree — a tree that fails
/// only costs the rows, not the products.
class CategoryBody extends StatelessWidget {
  const CategoryBody({super.key, required this.onRefresh});

  /// Reloads the tree and the products.
  final Future<void> Function() onRefresh;

  static const int _railLevel = 0;
  static const int _chipsLevel = 1;

  @override
  Widget build(BuildContext context) {
    return ProductListingBody(
      onRefresh: onRefresh,
      headerSlivers: const [
        SliverToBoxAdapter(child: CategoryRail(level: _railLevel)),
        SliverToBoxAdapter(child: CategoryChips(level: _chipsLevel)),
      ],
    );
  }
}
