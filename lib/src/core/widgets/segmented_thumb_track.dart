import 'package:flutter/material.dart';

import '../motion/haptics.dart';
import '../motion/motion.dart';

/// Builds one slot of a [SegmentedThumbTrack]. [select] is the slot's tap
/// (`null` while the track is inert); [position] is where the thumb is, in
/// slots (0 = the first), for a label whose colour follows the thumb.
typedef SegmentBuilder = Widget Function(
  BuildContext context,
  int index,
  VoidCallback? select,
  Animation<double> position,
);

/// THE segmented control's track (docs/motion §9.4 #27, backlog B2-09): equal
/// slots in a row with ONE thumb under the selected one — settings'
/// language switch and checkout's delivery / pickup (`HeroSegmentedControl`),
/// the Cart tab's cart / history pill, My coupons' tabs and Pro's plan tabs
/// all ride it, so every thumb moves the same way:
///
/// * it slides with the calm spring ([AppMotion.thumbSlide]) from wherever it
///   is (a new pick mid-slide retargets it); reduced motion → it jumps;
/// * it mirrors under RTL (the first slot sits at the start edge; a
///   paint-only translation, one `RepaintBoundary`);
/// * a tap on another slot fires the selection haptic (`Haptics.pick`), once,
///   then [onSelected]; a tap on the selected slot does nothing;
/// * [position] can drive it from outside instead, in slots (a
///   `TabController.animation`: a swipe of the pages drags the thumb along).
///
/// The track fills its parent's height; slots share its width, or are
/// [slotWidth] wide (a row that scrolls), [gap] apart. The slots are drawn
/// over the thumb, so they must be see-through.
class SegmentedThumbTrack extends StatefulWidget {
  const SegmentedThumbTrack({
    super.key,
    required this.count,
    required this.selected,
    required this.thumb,
    required this.segmentBuilder,
    this.onSelected,
    this.position,
    this.slotWidth,
    this.gap = 0,
    this.clipBehavior = Clip.hardEdge,
  });

  final int count;

  /// The selected slot; -1 = none (no thumb).
  final int selected;

  /// What slides under the selected slot (its decoration).
  final Widget thumb;
  final SegmentBuilder segmentBuilder;

  /// A slot other than [selected] was tapped; `null` = inert.
  final ValueChanged<int>? onSelected;

  /// Drives the thumb from outside, in slots; `null` = the track slides it
  /// to [selected] itself.
  final Animation<double>? position;

  /// Fixed slot width (the track is then exactly as wide as its slots);
  /// `null` = the slots share the parent's width.
  final double? slotWidth;
  final double gap;
  final Clip clipBehavior;

  @override
  State<SegmentedThumbTrack> createState() => _SegmentedThumbTrackState();
}

class _SegmentedThumbTrackState extends State<SegmentedThumbTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController.unbounded(
    vsync: this,
    value: widget.selected < 0 ? 0 : widget.selected.toDouble(),
  );

  @override
  void didUpdateWidget(SegmentedThumbTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final to = widget.selected;
    if (to == oldWidget.selected || to < 0) return;
    if (oldWidget.selected < 0 || MotionGuard.reduced(context)) {
      _slide.value = to.toDouble();
      return;
    }
    final spring = AppMotion.thumbSlide;
    _slide.animateTo(to.toDouble(), duration: spring.duration, curve: spring);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  VoidCallback? _selectOf(int index) {
    final onSelected = widget.onSelected;
    if (onSelected == null) return null;
    return () {
      if (index == widget.selected) return;
      Haptics.pick();
      onSelected(index);
    };
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    if (count <= 0) return const SizedBox.shrink();
    final gaps = widget.gap * (count - 1);
    final fixed = widget.slotWidth;
    final position = widget.position ?? _slide;
    final towardsEnd = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final track = LayoutBuilder(
      builder: (context, constraints) {
        final slot = fixed ?? (constraints.maxWidth - gaps) / count;
        final step = slot + widget.gap;
        return Stack(
          clipBehavior: widget.clipBehavior,
          children: [
            if (widget.selected >= 0 || widget.position != null)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: slot,
                child: AnimatedBuilder(
                  animation: position,
                  builder: (context, thumb) => Transform.translate(
                    offset: Offset(position.value * step * towardsEnd, 0),
                    child: thumb,
                  ),
                  child: RepaintBoundary(child: widget.thumb),
                ),
              ),
            for (var i = 0; i < count; i++)
              PositionedDirectional(
                start: i * step,
                top: 0,
                bottom: 0,
                width: slot,
                child: widget.segmentBuilder(
                  context,
                  i,
                  _selectOf(i),
                  position,
                ),
              ),
          ],
        );
      },
    );
    return fixed == null
        ? track
        : SizedBox(width: fixed * count + gaps, child: track);
  }
}
