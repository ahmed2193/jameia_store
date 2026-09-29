import 'package:flutter/material.dart';

import '../motion/haptics.dart';
import 'refresh_disc_header.dart';

/// Pull-to-refresh with the Hero loader. The platform [RefreshIndicator]
/// still runs the gesture — the threshold, the snap, the [onRefresh] future —
/// but draws no spinner: a small white disc ([RefreshDiscHeader]) comes down
/// with the finger instead, its dots swapping as the pull nears the
/// threshold, a selection click once a release would refresh, then the dots
/// loop at the rest line until [onRefresh] completes and the disc shrinks
/// away.
///
/// The [child] must be a scrollable (or contain one with
/// `AlwaysScrollableScrollPhysics`) for the pull gesture to register.
class BrandedRefresh extends StatefulWidget {
  const BrandedRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// How far down the disc starts: the height of a bar pinned over the top
  /// of the list, so the disc comes out from under it.
  final double edgeOffset;

  @override
  State<BrandedRefresh> createState() => _BrandedRefreshState();
}

class _BrandedRefreshState extends State<BrandedRefresh> {
  /// A full pull is this share of the viewport and a release refreshes from
  /// two thirds of it — [RefreshIndicator]'s own measures.
  static const double _fullPullShare = 0.25;
  static const double _armedShare = 2 / 3;

  /// The furthest pull the indicator measures, in armed units.
  static const double _maxPull = 1 / _armedShare;

  final ValueNotifier<double> _pull = ValueNotifier<double>(0);
  final ValueNotifier<RefreshDiscPhase> _phase =
      ValueNotifier<RefreshDiscPhase>(RefreshDiscPhase.idle);
  double _dragOffset = 0;

  @override
  void dispose() {
    _pull.dispose();
    _phase.dispose();
    super.dispose();
  }

  void _onStatus(RefreshIndicatorStatus? status) {
    switch (status) {
      case RefreshIndicatorStatus.drag:
        _dragOffset = 0;
        _pull.value = 0;
        _phase.value = RefreshDiscPhase.pulling;
      case RefreshIndicatorStatus.armed:
        Haptics.pick();
        _phase.value = RefreshDiscPhase.armed;
      case RefreshIndicatorStatus.snap || RefreshIndicatorStatus.refresh:
        _phase.value = RefreshDiscPhase.refreshing;
      case RefreshIndicatorStatus.done:
        _phase.value = RefreshDiscPhase.done;
      case RefreshIndicatorStatus.canceled:
        _phase.value = RefreshDiscPhase.canceled;
      case null:
        _phase.value = RefreshDiscPhase.idle;
    }
  }

  /// Measures the pull the way [RefreshIndicator] does (it does not share
  /// it): scroll and overscroll of the outermost scrollable while a pull is
  /// on.
  bool _onScroll(ScrollNotification notification) {
    final phase = _phase.value;
    if (notification.depth != 0 ||
        (phase != RefreshDiscPhase.pulling &&
            phase != RefreshDiscPhase.armed)) {
      return false;
    }
    final moved = switch (notification) {
      ScrollUpdateNotification(:final scrollDelta?) => -scrollDelta,
      OverscrollNotification(:final overscroll) => -overscroll,
      _ => null,
    };
    if (moved == null) return false;
    final metrics = notification.metrics;
    _dragOffset += metrics.axisDirection == AxisDirection.up ? -moved : moved;
    final full = metrics.viewportDimension * _fullPullShare * _armedShare;
    _pull.value = (_dragOffset / full).clamp(0.0, _maxPull);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator.noSpinner(
            onRefresh: widget.onRefresh,
            onStatusChange: _onStatus,
            child: widget.child,
          ),
        ),
        PositionedDirectional(
          top: widget.edgeOffset,
          start: 0,
          end: 0,
          child: RefreshDiscHeader(pull: _pull, phase: _phase),
        ),
      ],
    );
  }
}
