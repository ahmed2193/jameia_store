import 'package:flutter/widgets.dart';

/// ON-SCREEN GATE (docs/motion §9.3, D15) — tells a [State] whether its box
/// can be seen right now, so decorative motion runs only then. [onScreen] is
/// `false` while:
///
/// * the box lies outside the screen, or outside the visible part of any
///   `Scrollable` around it (a vertical feed, a horizontal rail in it), or
///   has no size (folded away);
/// * the app is in the background (hidden / paused / detached).
///
/// Hidden shell tabs and covered routes are `TickerMode`'s: read
/// `MotionGuard.ambientAllowed` beside this. The box is measured after the
/// layout of the frame that scrolled or rebuilt it (one check per frame at
/// most); before the first measure it counts as on screen, so a loop on
/// screen at launch starts on its first frame. Implement [onScreenChanged]
/// to start / stop the motion.
mixin OnScreenGate<T extends StatefulWidget> on State<T> {
  final List<ScrollPosition> _gatePositions = <ScrollPosition>[];
  AppLifecycleListener? _gateLifecycle;
  Size _gateScreen = Size.zero;
  bool _gateInView = true;
  bool _gateForeground = true;
  bool _gateCheckScheduled = false;

  /// On screen, with the app in the foreground.
  bool get onScreen => _gateInView && _gateForeground;

  /// [onScreen] changed; called outside a build.
  @protected
  void onScreenChanged();

  @override
  void initState() {
    super.initState();
    _gateForeground = _foreground(WidgetsBinding.instance.lifecycleState);
    _gateLifecycle = AppLifecycleListener(onStateChange: _gateLifecycleChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gateScreen = MediaQuery.sizeOf(context);
    _gateFollowScrollables();
    scheduleOnScreenCheck();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    scheduleOnScreenCheck();
  }

  @override
  void dispose() {
    for (final position in _gatePositions) {
      position.removeListener(scheduleOnScreenCheck);
    }
    _gatePositions.clear();
    _gateLifecycle?.dispose();
    super.dispose();
  }

  /// Measures the box again after this frame's layout.
  @protected
  void scheduleOnScreenCheck() {
    if (_gateCheckScheduled) return;
    _gateCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gateCheckScheduled = false;
      _gateCheck();
    });
  }

  static bool _foreground(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  void _gateLifecycleChanged(AppLifecycleState state) {
    final foreground = _foreground(state);
    if (foreground == _gateForeground || !mounted) return;
    _gateForeground = foreground;
    onScreenChanged();
  }

  /// Listens to every scroll position around the box: the nearest one as a
  /// dependency (a new controller re-subscribes), the outer ones found from
  /// there.
  void _gateFollowScrollables() {
    final positions = <ScrollPosition>[];
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      positions.add(scrollable.position);
      scrollable = scrollable.context
          .findAncestorStateOfType<ScrollableState>();
    }
    if (_samePositions(positions)) return;
    for (final position in _gatePositions) {
      position.removeListener(scheduleOnScreenCheck);
    }
    _gatePositions
      ..clear()
      ..addAll(positions);
    for (final position in positions) {
      position.addListener(scheduleOnScreenCheck);
    }
  }

  bool _samePositions(List<ScrollPosition> positions) {
    if (positions.length != _gatePositions.length) return false;
    for (var i = 0; i < positions.length; i++) {
      if (!identical(positions[i], _gatePositions[i])) return false;
    }
    return true;
  }

  void _gateCheck() {
    if (!mounted) return;
    final box = context.findRenderObject();
    // Not laid out (yet): keep the last answer.
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final inView = !box.size.isEmpty && _visible(box);
    if (inView == _gateInView) return;
    _gateInView = inView;
    onScreenChanged();
  }

  bool _visible(RenderBox box) {
    var shown = _globalRect(box).intersect(Offset.zero & _gateScreen);
    if (!_hasArea(shown)) return false;
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      final viewport = scrollable.context.findRenderObject();
      if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
        shown = shown.intersect(_globalRect(viewport));
        if (!_hasArea(shown)) return false;
      }
      scrollable = scrollable.context
          .findAncestorStateOfType<ScrollableState>();
    }
    return true;
  }

  static Rect _globalRect(RenderBox box) => MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );

  static bool _hasArea(Rect rect) => rect.width > 0 && rect.height > 0;
}
