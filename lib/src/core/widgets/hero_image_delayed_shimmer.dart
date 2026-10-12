import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../media/image_placeholder_anchor.dart';

/// [still] first; [shimmer] only if this is still mounted [delay] after the
/// FIRST FRAME that painted the placeholder. ONE widget whose own state
/// flips once, so the slot octo_image fills never changes shape around it.
/// A load that lands first unmounts it and cancels the timer: a fast load
/// never shows the shimmer at all.
///
/// The delay counts from [anchor] (the tile's [ImagePlaceholderAnchor]; its
/// own when null), which this sets at the end of its first frame — NOT at
/// mount: on a cold start the first frame can land long after the first
/// screen mounts, and a deadline counted from mount would be spent before
/// anything was painted. Until that frame the still child shows, with no
/// timer. An [anchor] already set (a remount of a tile that is waiting)
/// resumes from it: one already past mounts live, with no timer. A rebuild
/// with the same [delay] re-arms nothing.
class HeroImageDelayedShimmer extends StatefulWidget {
  const HeroImageDelayedShimmer({
    super.key,
    required this.delay,
    this.anchor,
    required this.still,
    required this.shimmer,
  });

  final Duration delay;
  final ImagePlaceholderAnchor? anchor;
  final Widget still;
  final WidgetBuilder shimmer;

  @override
  State<HeroImageDelayedShimmer> createState() =>
      _HeroImageDelayedShimmerState();
}

class _HeroImageDelayedShimmerState extends State<HeroImageDelayedShimmer> {
  late final ImagePlaceholderAnchor _anchor =
      widget.anchor ?? ImagePlaceholderAnchor();
  Timer? _timer;
  bool _live = false;
  bool _framePending = false;

  @override
  void initState() {
    super.initState();
    if (_anchor.atUs == null) {
      _awaitFirstFrame();
    } else {
      _arm();
    }
  }

  // The delay moves only when the tile re-decided (network → disk once the
  // disk-index seed lands: a longer delay from the same anchor). Waiting:
  // re-arm on what is left. Live: stay live — a running sweep never snaps
  // back to the still box. Before the first frame nothing is armed: the
  // pending callback reads the delay current at that frame.
  @override
  void didUpdateWidget(HeroImageDelayedShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_live || widget.delay == oldWidget.delay) return;
    _timer?.cancel();
    _timer = null;
    if (_anchor.atUs != null) _arm();
  }

  // Anchors at the end of the first frame this is built in — the placeholder
  // has just been painted — and makes sure such a frame comes.
  void _awaitFirstFrame() {
    if (_framePending) return;
    _framePending = true;
    SchedulerBinding.instance
      ..addPostFrameCallback(_anchored)
      ..ensureVisualUpdate();
  }

  void _anchored(Duration _) {
    _framePending = false;
    if (!mounted) return;
    _anchor.atUs ??= ImagePlaceholderClock.nowUs;
    final bool wasLive = _live;
    _arm();
    if (_live != wasLive) setState(() {});
  }

  // Live once the delay has passed; else one timer for what is left.
  void _arm() {
    _timer?.cancel();
    final Duration left = _anchor.left(widget.delay) ?? widget.delay;
    _live = left == Duration.zero;
    _timer = _live ? null : Timer(left, _goLive);
  }

  void _goLive() {
    _timer = null;
    if (mounted) setState(() => _live = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _live ? widget.shimmer(context) : widget.still;
}
