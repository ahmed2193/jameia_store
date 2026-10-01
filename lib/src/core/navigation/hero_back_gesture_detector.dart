import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/motion.dart';
import 'hero_back_gesture.dart';
import 'hero_page_route.dart';

/// Feeds the platform back gestures to its [HeroPageRoute]:
///
/// - Android 14+ predictive back (needs `enableOnBackInvokedCallback` in the
///   manifest): the system reports the edge gesture to every
///   [WidgetsBindingObserver]; only the route on top that may pop takes it.
///   A button back or a refused start falls through to the usual pop (so a
///   `PopScope` still decides).
/// - iOS: an edge swipe from the start edge (mirrored in RTL), like
///   Cupertino's, driving the route's own pop 1:1; a fling or more than half
///   the width pops.
class HeroBackGestureDetector extends StatefulWidget {
  const HeroBackGestureDetector({
    super.key,
    required this.route,
    required this.child,
  });

  final HeroPageRoute<dynamic> route;
  final Widget child;

  /// Width of the iOS edge strip the swipe starts in (Cupertino's).
  static const double edgeWidth = 20;

  /// A fling this fast (screen widths per second) decides on its own.
  static const double flingWidthsPerSecond = 1;

  @override
  State<HeroBackGestureDetector> createState() =>
      _HeroBackGestureDetectorState();
}

class _HeroBackGestureDetectorState extends State<HeroBackGestureDetector>
    with WidgetsBindingObserver {
  late final HorizontalDragGestureRecognizer _swipe =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _onSwipeStart
        ..onUpdate = _onSwipeUpdate
        ..onEnd = _onSwipeEnd
        ..onCancel = _onSwipeCancel;

  bool _swiping = false;
  double _swipeProgress = 0;

  HeroPageRoute<dynamic> get _route => widget.route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _swipe.dispose();
    super.dispose();
  }

  bool get _ownsPredictive =>
      _route.backGesture.value?.kind == HeroBackGestureKind.predictive;

  // ── Android predictive back ──────────────────────────────────────────────

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_route.canStartBackGesture) return false;
    _route
      ..startBackGesture(
        HeroBackGestureKind.predictive,
        fromLeftEdge: backEvent.swipeEdge == SwipeEdge.left,
      )
      ..updateBackGesture(backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_ownsPredictive) _route.updateBackGesture(backEvent.progress);
  }

  @override
  void handleCommitBackGesture() {
    if (_ownsPredictive) {
      _route.endBackGesture(commit: true, instant: MotionGuard.off(context));
    }
  }

  @override
  void handleCancelBackGesture() {
    if (_ownsPredictive) {
      _route.endBackGesture(commit: false, instant: MotionGuard.off(context));
    }
  }

  // ── iOS edge swipe ───────────────────────────────────────────────────────

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  void _onPointerDown(PointerDownEvent event) {
    if (_route.canStartBackGesture) _swipe.addPointer(event);
  }

  void _onSwipeStart(DragStartDetails details) {
    _swipeProgress = 0;
    // Another gesture already drives the route: this swipe stays out.
    _swiping = _route.startBackGesture(
      HeroBackGestureKind.swipe,
      fromLeftEdge: !_rtl,
    );
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    if (!_swiping) return;
    final width = context.size?.width ?? 0;
    if (width <= 0) return;
    final delta = (details.primaryDelta ?? 0) / width;
    _swipeProgress = (_swipeProgress + (_rtl ? -delta : delta)).clamp(0, 1);
    _route.updateBackGesture(_swipeProgress);
  }

  void _onSwipeEnd(DragEndDetails details) {
    if (!_swiping) return;
    _swiping = false;
    final width = context.size?.width ?? 1;
    final velocity =
        details.velocity.pixelsPerSecond.dx / width * (_rtl ? -1 : 1);
    final commit =
        velocity.abs() >= HeroBackGestureDetector.flingWidthsPerSecond
        ? velocity > 0
        : _swipeProgress > HeroPageRoute.commitShare;
    _route.endBackGesture(commit: commit, instant: MotionGuard.off(context));
  }

  void _onSwipeCancel() {
    if (!_swiping) return;
    _swiping = false;
    _route.endBackGesture(commit: false, instant: MotionGuard.off(context));
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) return widget.child;
    // A notch widens the strip on its side.
    final padding = MediaQuery.paddingOf(context);
    final strip = math.max(
      _rtl ? padding.right : padding.left,
      HeroBackGestureDetector.edgeWidth,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: strip,
          child: Listener(
            onPointerDown: _onPointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}
