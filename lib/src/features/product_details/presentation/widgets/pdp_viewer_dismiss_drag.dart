import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/navigation/navigation.dart';

/// Drag down to dismiss for the photo viewer (docs/motion B2-08): a
/// one-finger drag down on a photo at rest pulls the whole presentation down
/// with the finger — its own route's slide-down, so the product page shows
/// through as the viewer fades with the pull. Let go past [dismissShare] of
/// the height, or flung down, and the viewer closes through [onDismiss]
/// (which pops with the page it was left on); short of it, it springs back.
/// Instant settle / exit under reduced motion; the pull itself follows the
/// finger.
class PdpViewerDismissDrag {
  PdpViewerDismissDrag({required this.onDismiss});

  /// Pops the viewer with its result.
  final VoidCallback onDismiss;

  /// Share of the screen height a release must pass to dismiss.
  static const double dismissShare = 0.2;

  /// A downward fling this fast (dp/s) dismisses from anywhere.
  static const double flingVelocity = 700;

  HeroPageRoute<dynamic>? _route;
  double _pulled = 0;

  bool get isActive => _route != null;

  /// The finger moved [dy] (down is positive).
  void update(BuildContext context, double dy) {
    var route = _route;
    if (route == null) {
      final modal = ModalRoute.of(context);
      if (modal is! HeroPageRoute<dynamic> || !modal.canStartDrag) return;
      if (dy <= 0) return;
      // Another gesture drives the route: this drag leaves it alone.
      if (!modal.startBackGesture(HeroBackGestureKind.drag)) return;
      route = _route = modal;
      _pulled = 0;
    }
    final height = MediaQuery.sizeOf(context).height;
    if (height <= 0) return;
    _pulled = (_pulled + dy).clamp(0, height);
    route.updateBackGesture(_pulled / height);
  }

  /// The finger let go at [velocityY] (dp/s, down is positive).
  void end(BuildContext context, double velocityY) {
    final route = _route;
    if (route == null) return;
    _route = null;
    final height = MediaQuery.sizeOf(context).height;
    final dismiss =
        velocityY >= flingVelocity ||
        (height > 0 && _pulled / height > dismissShare);
    route.endBackGesture(
      commit: dismiss,
      pop: onDismiss,
      instant: MotionGuard.reduced(context),
    );
  }

  /// The drag turned into something else (a second finger): spring back.
  void cancel(BuildContext context) {
    final route = _route;
    if (route == null) return;
    _route = null;
    route.endBackGesture(commit: false, instant: MotionGuard.reduced(context));
  }
}
