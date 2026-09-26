import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../motion/motion.dart';
import 'collection_tab_strip.dart';

/// Pins a collection's [CollectionTabStrip] under the top bar: white, with a
/// hairline, and a soft shadow once the grid scrolls underneath.
class CollectionTabsDelegate extends SliverPersistentHeaderDelegate {
  const CollectionTabsDelegate({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  static const double _hairline = 1;

  @override
  double get maxExtent => CollectionTabStrip.height + _hairline;

  @override
  double get minExtent => maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return AnimatedContainer(
      height: maxExtent,
      duration: MotionGuard.duration(context, AppMotion.fast),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
        boxShadow: overlapsContent ? AppShadows.low : const <BoxShadow>[],
      ),
      child: CollectionTabStrip(
        labels: labels,
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  bool shouldRebuild(CollectionTabsDelegate oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.onSelected != onSelected ||
      !_sameLabels(oldDelegate.labels, labels);

  static bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
