import 'package:flutter/material.dart';

import '../../../../core/widgets/skeletonized.dart';
import 'offer_skeleton_card.dart';
import 'offers_list_sliver.dart';

/// What the offers page shows under its hero while the offers load: a few
/// shimmering offer cards in the list's own gutters and gaps (still bones
/// under reduced motion). Reads to nobody.
class OffersSkeleton extends StatelessWidget {
  const OffersSkeleton({super.key});

  static const int _cards = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      child: Skeletonized(
        loading: true,
        child: Padding(
          padding: OffersListSliver.padding,
          child: Column(
            spacing: OffersListSliver.gap,
            children: [
              for (var card = 0; card < _cards; card++)
                const OfferSkeletonCard(),
            ],
          ),
        ),
      ),
    );
  }
}
