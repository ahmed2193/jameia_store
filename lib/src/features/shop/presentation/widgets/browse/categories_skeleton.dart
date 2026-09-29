import 'package:flutter/material.dart';

import '../../../../../core/widgets/skeletonized.dart';
import '../listing/listing_grid_skeleton.dart';
import 'category_rail_skeleton.dart';

/// What the store page shows while its category tree loads with nothing
/// saved: the rail's bones over the listing's own grid bones
/// ([ListingGridSkeleton] — the same bones the products then load under),
/// so the page takes its shape before the tree arrives.
class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeletonized(loading: true, child: CategoryRailSkeleton()),
          ListingGridSkeleton(),
        ],
      ),
    );
  }
}
