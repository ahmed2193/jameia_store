import 'package:flutter/material.dart';

import '../../../../../core/widgets/skeletonized.dart';
import 'listing_skeleton_card.dart';
import 'product_grid_sliver.dart';

/// What a listing shows while its products load: two rows of shimmering card
/// bones in the grid's own columns and gaps ([ProductGridSliver]), so the
/// real cards land where the bones were. Solid bones under reduced motion.
class ListingGridSkeleton extends StatelessWidget {
  const ListingGridSkeleton({super.key});

  static const int _rows = 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ProductGridSliver.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = ProductGridSliver.columnsFor(constraints.maxWidth);
          final cellWidth = ProductGridSliver.cellWidthFor(
            constraints.maxWidth,
            columns,
          );
          return Skeletonized(
            loading: true,
            child: Wrap(
              spacing: ProductGridSliver.crossGap,
              runSpacing: ProductGridSliver.mainGap,
              children: [
                for (var i = 0; i < columns * _rows; i++)
                  ListingSkeletonCard(width: cellWidth),
              ],
            ),
          );
        },
      ),
    );
  }
}
