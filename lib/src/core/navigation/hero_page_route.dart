import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import 'hero_back_gesture.dart';
import 'hero_page.dart';
import 'hero_route_transition.dart';

/// The route every [HeroPage] creates: the page's entrance, the covered
/// page's shift and the back gestures ([HeroRouteTransition]).
///
/// A back gesture drives this route's own controller: [startBackGesture] →
/// [updateBackGesture] (0 = at rest → 1 = gone) → [endBackGesture]. The same
/// calls serve a page's own drag to dismiss (the photo viewer).
class HeroPageRoute<T> extends PageRoute<T> {
  HeroPageRoute(HeroPage<T> page) : super(settings: page);

  /// Past this share of the way (or on a fling) a released swipe pops.
  static const double commitShare = 0.5;

  /// The page this route shows (updated in place by the Navigator).
  HeroPage<T> get page => settings as HeroPage<T>;

  /// The back gesture driving this route, `null` when none.
  ValueListenable<HeroBackGesture?> get backGesture => _backGesture;
  final ValueNotifier<HeroBackGesture?> _backGesture =
      ValueNotifier<HeroBackGesture?>(null);
  bool _disposed = false;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => page.reverseTransitionDuration;

  @override
  bool get opaque => page.opaque;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  String get debugLabel => '${super.debugLabel}(${page.name})';

  /// The page below moves (and so gets a secondary animation) only under a
  /// page that [HeroPage.shiftsCoveredPage]; under a modal it holds still.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is HeroPageRoute && nextRoute.page.shiftsCoveredPage;

  /// A platform back gesture may start: on top, at rest, something below,
  /// and no `PopScope` in the way ([popGestureEnabled]).
  bool get canStartBackGesture => isCurrent && popGestureEnabled;

  /// A page's own drag to dismiss may start: on top, at rest, something
  /// below. A `PopScope` does not stop it — the page pops itself.
  bool get canStartDrag =>
      isCurrent && !isFirst && (animation?.isCompleted ?? false);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      Semantics(scopesRoute: true, explicitChildNodes: true, child: page.child);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => HeroRouteTransition(
    route: this,
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );

  /// The finger went down on a back gesture of [kind].
  void startBackGesture(HeroBackGestureKind kind, {bool fromLeftEdge = true}) {
    if (_backGesture.value != null) return;
    _backGesture.value = HeroBackGesture(
      kind: kind,
      fromLeftEdge: fromLeftEdge,
    );
    navigator?.didStartUserGesture();
  }

  /// The gesture got [progress] of the way (0 = at rest → 1 = gone).
  void updateBackGesture(double progress) {
    final gesture = _backGesture.value;
    if (gesture == null ||
        gesture.phase != HeroBackGesturePhase.tracking ||
        !isCurrent) {
      return;
    }
    final share = progress.clamp(0.0, 1.0);
    controller?.value = 1 - share;
    _backGesture.value = gesture.copyWith(progress: share);
  }

  /// The finger let go: pop ([commit]) — through [pop] when the page pops
  /// itself with a result — or settle back. [instant] (reduced motion) skips
  /// the settle / exit animation.
  void endBackGesture({
    required bool commit,
    VoidCallback? pop,
    bool instant = false,
  }) {
    final gesture = _backGesture.value;
    final controller = this.controller;
    if (gesture == null || controller == null) return;
    _backGesture.value = gesture.copyWith(
      phase: commit
          ? HeroBackGesturePhase.committing
          : HeroBackGesturePhase.cancelling,
    );
    final predictive = gesture.kind == HeroBackGestureKind.predictive;
    if (commit) {
      // Another navigation beat the release: nothing left to pop.
      if (isCurrent) {
        (pop ?? () => navigator?.pop())();
        if (instant) {
          controller.animateBack(0, duration: Duration.zero);
        } else if (controller.isAnimating) {
          if (predictive) {
            // The shrunken page plays the whole pop from where it rests.
            controller.reverse(from: controller.upperBound);
          } else {
            controller.animateBack(
              0,
              duration: reverseTransitionDuration * controller.value,
              curve: AppMotion.exit,
            );
          }
        }
      }
    } else {
      // The edge swipe settles like a page; a pull (predictive, a drag)
      // springs back.
      final swipe = gesture.kind == HeroBackGestureKind.swipe;
      controller.animateTo(
        1,
        duration: instant
            ? Duration.zero
            : (swipe ? AppMotion.medium : AppSprings.calm.duration),
        curve: swipe ? AppMotion.signature : AppSprings.calm,
      );
    }
    if (controller.isAnimating) {
      late final AnimationStatusListener onDone;
      onDone = (status) {
        if (status.isAnimating) return;
        controller.removeStatusListener(onDone);
        _finishGesture();
      };
      controller.addStatusListener(onDone);
    } else {
      _finishGesture();
    }
  }

  void _finishGesture() {
    if (_disposed) return;
    _backGesture.value = null;
    navigator?.didStopUserGesture();
  }

  @override
  void dispose() {
    // Removed mid-gesture (a `go` under the finger): let the navigator
    // know the gesture is over once this frame is done.
    if (_backGesture.value != null) {
      final navigator = this.navigator;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (navigator != null && navigator.mounted) {
          navigator.didStopUserGesture();
        }
      });
    }
    _disposed = true;
    _backGesture.dispose();
    super.dispose();
  }
}
