import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../cubit/category_browse_cubit.dart';
import '../listing/product_listing_body.dart';
import 'category_chips.dart';
import 'category_rail_header.dart';
import 'category_tree_failure_listener.dart';

/// Body of a category page: the sub-category rail (pinned, folding into chips
/// while scrolling), its chips and the products
/// of whatever is picked. The product list is scoped by the slug the page was
/// opened with, so it never waits for the category tree — a tree that fails
/// only costs the rows, not the products (asked again when the connection
/// returns) — and says so ([CategoryTreeFailureListener]) instead of the
/// rows just not being there.
class CategoryBody extends StatelessWidget {
  const CategoryBody({super.key, required this.onRefresh});

  /// Reloads the tree and the products.
  final Future<void> Function() onRefresh;

  static const int _railLevel = 0;
  static const int _chipsLevel = 1;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<CategoryBrowseCubit>().onReconnected(),
      child: CategoryTreeFailureListener(
        child: ProductListingBody(
          onRefresh: onRefresh,
          headerSlivers: const [
            CategoryRailHeader(level: _railLevel),
            SliverToBoxAdapter(child: CategoryChips(level: _chipsLevel)),
          ],
        ),
      ),
    );
  }
}
