import 'package:flutter/material.dart';

import '../../../../core/widgets/skeletons.dart';

/// Home while the feed is on its way: the sliver under the real header
/// ([HomeFrame]) — the delivery line and the search pill are usable from the
/// first frame and do not jump (or replay) when the feed lands; only the
/// body below them is skeletal.
class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) => const SliverToBoxAdapter(
    child: Skeletonized(loading: true, child: HomeSkeleton()),
  );
}
