import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import 'category_rail.dart';
import 'category_rail_chip.dart';
import 'category_rail_compact.dart';

/// Lays out the sub-category rail as a header that never leaves the top of
/// the listing: at rest it is the full rail of circles (picture above the
/// name); as the list scrolls up under it, the circles ride away and fade
/// while a row of chips (picture beside the name) fades in, and that row
/// stays. Scrolling back down unfolds the circles again. Everything follows
/// the finger, so nothing moves on its own; under reduced motion the two
/// rows swap at the halfway point instead of cross-fading.
class CategoryRailHeaderDelegate extends SliverPersistentHeaderDelegate {
  const CategoryRailHeaderDelegate({required this.level});

  /// The browse level the rail offers.
  final int level;

  /// The folded header: one row of chips with a little air around it.
  static const double foldedHeight = CategoryRailChip.height + AppSpacing.s20;

  /// Each row fades over its half of the fold, so the two never overlap.
  static const Interval _railFade = Interval(0, _halfway);
  static const Interval _chipsFade = Interval(_halfway, 1);
  static const double _halfway = 0.5;

  /// How far the chips rise as they arrive.
  static const double _chipsRise = AppSpacing.s8;

  @override
  double get maxExtent => CategoryRail.height;

  @override
  double get minExtent => foldedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final folded = (shrinkOffset / range).clamp(0.0, 1.0);
    final still = MotionGuard.reduced(context);
    final chipsShown = folded >= _halfway;
    final railOpacity = still
        ? (chipsShown ? 0.0 : 1.0)
        : 1 - _railFade.transform(folded);
    final chipsOpacity = still
        ? (chipsShown ? 1.0 : 0.0)
        : _chipsFade.transform(folded);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        // A hairline once products pass underneath.
        border: folded >= 1
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.divider,
                  width: AppSize.s0_5,
                ),
              )
            : null,
      ),
      child: ClipRect(
        child: Stack(
          children: [
            PositionedDirectional(
              top: -shrinkOffset.clamp(0.0, range),
              start: 0,
              end: 0,
              height: maxExtent,
              child: IgnorePointer(
                ignoring: chipsShown,
                child: ExcludeSemantics(
                  excluding: chipsShown,
                  child: Opacity(
                    opacity: railOpacity,
                    child: CategoryRail(level: level),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              height: minExtent,
              child: IgnorePointer(
                ignoring: !chipsShown,
                child: ExcludeSemantics(
                  excluding: !chipsShown,
                  child: Opacity(
                    opacity: chipsOpacity,
                    child: Transform.translate(
                      offset: Offset(0, (1 - chipsOpacity) * _chipsRise),
                      child: CategoryRailCompact(
                        level: level,
                        shown: chipsShown,
                        onPicked: () => _backToTop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A pick from the chips starts the new list from its top, where the rail
  /// unfolds into circles again.
  static void _backToTop(BuildContext context) {
    final list = Scrollable.maybeOf(context)?.position;
    if (list == null || !list.hasPixels || list.pixels <= 0) return;
    MotionGuard.scrollTo(
      context,
      list,
      0,
      duration: AppMotion.slow,
      curve: AppMotion.emphasizedDecelerate,
    );
  }

  @override
  bool shouldRebuild(CategoryRailHeaderDelegate oldDelegate) =>
      oldDelegate.level != level;
}
