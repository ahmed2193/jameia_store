import 'dart:async';

import 'package:flutter/material.dart';

import 'motion.dart';

/// SCROLL REVEAL — [child] fades in and rises by [beginOffset] the first time
/// its top edge comes into view inside the nearest vertical `Scrollable`
/// (sections below the fold animate as the customer reaches them). The ones
/// already in view when the list first lays out play after [delay] (a
/// cascade); a reveal the scroll brings in plays at once. Measured against
/// the Scrollable's own box, so a route transition or a bar laid over the
/// list (`extendBody`) does not count as on screen. Plays once, then stops
/// listening to the scroll position. No scrollable ancestor → plays on
/// mount. Reduced motion → shown as is.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = defaultBeginOffset,
    this.visibleFraction = defaultVisibleFraction,
  });

  static const Offset defaultBeginOffset = Offset(0, 0.12);

  /// How far down the visible band of the Scrollable (its box less the
  /// bottom inset a bar laid over it reserves) the top edge must be to
  /// count as seen (0.92 = just above the band's bottom edge).
  static const double defaultVisibleFraction = 0.92;

  final Widget child;
  final Duration delay;
  final Offset beginOffset;
  final double visibleFraction;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.emphasizedDecelerate,
  );
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  bool _started = false;
  bool _checkScheduled = false;

  /// The cascade delay of a reveal already in view; cancelled on dispose so
  /// a row the list drops never fires later.
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    if (MotionGuard.reduced(context)) {
      _started = true;
      _controller.value = 1;
      return;
    }
    // The reveal is vertical: a horizontal carousel in between is skipped.
    _scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    final position = _scrollable?.position;
    if (position != _position) {
      _position?.removeListener(_onScroll);
      _position = position?..addListener(_onScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(initial: true));
  }

  /// A scroll notification fires before the frame lays the list out, so the
  /// check waits for the end of that frame to read the new geometry.
  void _onScroll() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
  }

  /// [initial] = the first check after the item is laid out; only that one
  /// honours [ScrollReveal.delay].
  void _check({bool initial = false}) {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final band = _visibleBand(box);
    // A short last item may never lift its top above the line even at the
    // end of the scroll: being fully in view counts as seen too.
    final seen =
        band.top <= band.bottom * widget.visibleFraction ||
        band.top + box.size.height <= band.bottom;
    if (_position != null && !seen) return;
    _started = true;
    _position?.removeListener(_onScroll);
    _position = null;
    if (initial && widget.delay > Duration.zero) {
      _delay = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  /// [box]'s top edge and the bottom of the visible band, in the
  /// Scrollable's coordinates (transforms above it — a route sliding in —
  /// drop out). No usable Scrollable → the screen.
  ({double top, double bottom}) _visibleBand(RenderBox box) {
    final scrollable = _scrollable;
    final viewport = scrollable?.context.findRenderObject();
    if (scrollable != null &&
        viewport is RenderBox &&
        viewport.attached &&
        viewport.hasSize) {
      return (
        top: box.localToGlobal(Offset.zero, ancestor: viewport).dy,
        bottom: viewport.size.height - _coveredBottom(scrollable, viewport),
      );
    }
    return (
      top: box.localToGlobal(Offset.zero).dy,
      bottom: MediaQuery.sizeOf(context).height,
    );
  }

  /// How much of [viewport]'s bottom sits under the bottom inset its
  /// context still carries: a bar laid over the list under `extendBody`
  /// (a list consumes that padding only inside its slivers) or the system
  /// inset — counted only where the viewport actually reaches into it.
  double _coveredBottom(ScrollableState scrollable, RenderBox viewport) {
    final element = scrollable.context
        .getElementForInheritedWidgetOfExactType<MediaQuery>();
    final query = element?.widget;
    final inset = query is MediaQuery ? query.data.padding.bottom : 0.0;
    if (inset <= 0) return 0;
    // The inset is measured from the bottom of the box the MediaQuery
    // covers (the Scaffold body, or the screen).
    final area = element?.findRenderObject();
    if (area is! RenderBox || !area.attached || !area.hasSize) return 0;
    final areaBottom = area.localToGlobal(Offset(0, area.size.height)).dy;
    final viewportBottom = viewport
        .localToGlobal(Offset(0, viewport.size.height))
        .dy;
    return (viewportBottom - (areaBottom - inset)).clamp(0.0, inset);
  }

  @override
  void dispose() {
    _delay?.cancel();
    _position?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
