import 'package:flutter/material.dart';

import 'listing_grid_skeleton.dart';

/// A loading list's bones ([ListingGridSkeleton]) in a sliver at least one
/// screen tall: the scroll view keeps enough room under pinned headers that a
/// list restarted from its tabs does not pull the page back up.
class ListingViewportSkeleton extends StatelessWidget {
  const ListingViewportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
        ),
        child: const Align(
          alignment: AlignmentDirectional.topCenter,
          child: ListingGridSkeleton(),
        ),
      ),
    );
  }
}
