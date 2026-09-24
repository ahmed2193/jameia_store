import 'package:flutter/material.dart';

import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/skeletons.dart';
import 'home_header_sliver.dart';

/// Home while the feed is on its way. The header is real chrome, not a bone:
/// the delivery line and the search field are usable from the first frame and
/// do not jump when the feed lands — only the body below them is skeletal.
class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key, required this.fallbackPlace});

  /// The delivery area the store knows (`GET /v1/init`); empty until it lands.
  final String fallbackPlace;

  @override
  Widget build(BuildContext context) => ContentClamp(
    child: CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        HomeHeaderSliver(fallbackPlace: fallbackPlace),
        const SliverToBoxAdapter(
          child: Skeletonized(loading: true, child: HomeSkeleton()),
        ),
      ],
    ),
  );
}
