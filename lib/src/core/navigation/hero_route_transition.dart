import 'package:flutter/material.dart';

import '../motion/motion.dart';
import 'hero_back_gesture.dart';
import 'hero_back_gesture_detector.dart';
import 'hero_page_route.dart';

/// Everything a [HeroPageRoute] does around its page, in one place:
///
/// - the page's own entrance ([HeroPage.enter]) eased in with
///   [AppMotion.signature] and out like [AppMotion.exit] (the reverse leg
///   runs the flipped curve so the page accelerates away), or linear while a
///   finger drives it;
/// - the covered leg: under a forward page this page slides back by
///   [AppMotion.slideShift] toward the start edge (mirrored in RTL);
/// - Android predictive back: the page shrinks to [_minScale] and shifts with
///   the finger, a commit plays the page's own pop from there;
/// - reduced motion: a `fast` fade; animations off: a cut.
///
/// Stateful so its curves are built once: the route rebuilds this on every
/// tick of its own animation and of the one above it.
class HeroRouteTransition extends StatefulWidget {
  const HeroRouteTransition({
    super.key,
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final HeroPageRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<HeroRouteTransition> createState() => _HeroRouteTransitionState();
}

class _HeroRouteTransitionState extends State<HeroRouteTransition> {
  /// Android's predictive-back page: 90 % at full pull, shifted by a
  /// twentieth of the width less [_edgeMargin] (Material motion spec).
  static const double _minScale = 0.9;
  static const double _shiftDivisor = 20;
  static const double _edgeMargin = 8;

  /// Reduced motion: the fade takes this share of the push (`fast` of `page`).
  static final double _reducedShare =
      AppMotion.fast.inMicroseconds / AppMotion.page.inMicroseconds;

  late CurvedAnimation _eased;
  late CurvedAnimation _fade;
  late CurvedAnimation _cover;

  @override
  void initState() {
    super.initState();
    _makeCurves();
  }

  void _makeCurves() {
    _eased = CurvedAnimation(
      parent: widget.animation,
      curve: AppMotion.signature,
      reverseCurve: AppMotion.exit.flipped,
    );
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(0, _reducedShare),
      reverseCurve: Interval(1 - _reducedShare, 1),
    );
    _cover = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: AppMotion.signature,
      reverseCurve: AppMotion.exit.flipped,
    );
  }

  void _disposeCurves() {
    _eased.dispose();
    _fade.dispose();
    _cover.dispose();
  }

  @override
  void didUpdateWidget(HeroRouteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _disposeCurves();
      _makeCurves();
    }
  }

  @override
  void dispose() {
    _disposeCurves();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    return HeroBackGestureDetector(
      route: route,
      child: ValueListenableBuilder<HeroBackGesture?>(
        valueListenable: route.backGesture,
        child: widget.child,
        builder: (context, gesture, child) {
          final page = child!;
          if (MotionGuard.off(context)) return page;
          final reduced = MotionGuard.reduced(context);
          final predictive =
              !reduced && gesture?.kind == HeroBackGestureKind.predictive;
          final committing = gesture?.phase == HeroBackGesturePhase.committing;

          // The page's own entrance / pop; at rest while a predictive back
          // is still under the finger.
          final Widget framed = reduced
              ? FadeTransition(
                  opacity: gesture == null ? _fade : widget.animation,
                  child: page,
                )
              : route.page.enter(
                  context,
                  predictive && !committing
                      ? kAlwaysCompleteAnimation
                      : gesture == null || predictive
                      ? _eased
                      : widget.animation,
                  page,
                );

          // Android predictive back: shrink and shift with the finger;
          // frozen where it was let go while the pop plays.
          var pull = 0.0;
          var edge = 1.0;
          if (predictive) {
            pull = committing ? gesture!.progress : 1 - widget.animation.value;
            edge = gesture!.fromLeftEdge ? 1 : -1;
          }
          final width = MediaQuery.sizeOf(context).width;
          final pullShift = (width / _shiftDivisor - _edgeMargin) * pull * edge;

          // Covered by a forward page: slide back toward the start edge.
          // Held still under an Android back gesture (the page on top
          // previews over this one at rest); the iOS swipe drives it 1:1.
          var covered = 0.0;
          final secondary = widget.secondaryAnimation;
          if (!reduced && !secondary.isDismissed) {
            final gestureOnTop =
                route.navigator?.userGestureInProgress ?? false;
            if (!gestureOnTop) {
              covered = _cover.value;
            } else if (Theme.of(context).platform == TargetPlatform.iOS) {
              covered = secondary.value;
            }
          }
          final back = Directionality.of(context) == TextDirection.rtl
              ? 1.0
              : -1.0;

          // Paint-only transforms, always present so the page's subtree
          // never moves in the tree when a gesture starts or ends.
          return Transform.translate(
            offset: Offset(
              covered * AppMotion.slideShift * back + pullShift,
              0,
            ),
            child: Transform.scale(
              scale: 1 - (1 - _minScale) * pull,
              child: framed,
            ),
          );
        },
      ),
    );
  }
}
