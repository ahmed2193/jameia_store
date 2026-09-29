import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/segmented_thumb_track.dart';
import 'coupons_tab_pill.dart';

/// Segmented pill tabs of My coupons (Available / Used / Expired): equal
/// slots sharing the row, one dark thumb under the selected one — the app's
/// one thumb track ([SegmentedThumbTrack]). The thumb rides the page's
/// [controller]: a tap slides it on the calm spring (with a selection
/// haptic) while the lists slide along, and swiping the lists drags it.
class CouponsTabBar extends StatefulWidget {
  const CouponsTabBar({
    super.key,
    required this.controller,
    required this.labels,
    required this.counts,
  });

  final TabController controller;
  final List<String> labels;
  final List<int> counts;

  @override
  State<CouponsTabBar> createState() => _CouponsTabBarState();
}

class _CouponsTabBarState extends State<CouponsTabBar> {
  static const double _height = AppSize.s44;
  static const double _gap = AppSpacing.s8;

  static const Widget _thumb = DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primaryText,
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
      boxShadow: AppShadows.medium,
    ),
  );

  late int _selected = widget.controller.index;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_follow);
  }

  @override
  void didUpdateWidget(CouponsTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_follow);
    widget.controller.addListener(_follow);
    _selected = widget.controller.index;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_follow);
    super.dispose();
  }

  /// The controller also ticks while a swipe drags it; only a new index
  /// rebuilds the bar.
  void _follow() {
    final index = widget.controller.index;
    if (index != _selected) setState(() => _selected = index);
  }

  void _select(int index) {
    final spring = AppMotion.thumbSlide;
    widget.controller.animateTo(
      index,
      duration: MotionGuard.duration(context, spring.duration),
      curve: spring,
    );
  }

  @override
  Widget build(BuildContext context) {
    final animation = widget.controller.animation;
    if (animation == null) return const SizedBox.shrink();
    return SizedBox(
      height: _height,
      child: SegmentedThumbTrack(
        count: widget.labels.length,
        selected: _selected,
        position: animation,
        gap: _gap,
        thumb: _thumb,
        onSelected: _select,
        segmentBuilder: (context, i, select, position) => CouponsTabPill(
          label: widget.labels[i],
          count: widget.counts[i],
          index: i,
          animation: position,
          onTap: select,
        ),
      ),
    );
  }
}
