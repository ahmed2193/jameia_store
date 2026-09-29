import 'package:flutter/foundation.dart';

/// What drives a [HeroPageRoute] back while the finger is down.
enum HeroBackGestureKind {
  /// Android 14+ predictive back (the system edge gesture): the page
  /// shrinks and shifts with the finger, a commit plays the page's own pop.
  predictive,

  /// The iOS edge swipe: the finger drives the page's own transition.
  swipe,

  /// A page's own drag (the photo viewer's drag down): the finger drives the
  /// page's own transition, the page decides how it pops.
  drag,
}

/// Where a back gesture is.
enum HeroBackGesturePhase {
  /// The finger is down and moving.
  tracking,

  /// Released past the threshold: the page is leaving.
  committing,

  /// Released short of the threshold: the page settles back.
  cancelling,
}

/// One back gesture on a [HeroPageRoute]: its [kind], its [phase] and how
/// far it got ([progress], 0 = page at rest → 1 = page gone). Frozen at the
/// release, so a commit can play the pop from where the finger left it.
@immutable
class HeroBackGesture {
  const HeroBackGesture({
    required this.kind,
    this.phase = HeroBackGesturePhase.tracking,
    this.progress = 0,
    this.fromLeftEdge = true,
  });

  final HeroBackGestureKind kind;
  final HeroBackGesturePhase phase;
  final double progress;

  /// The screen edge the gesture started from (a predictive back shifts the
  /// page away from it).
  final bool fromLeftEdge;

  HeroBackGesture copyWith({HeroBackGesturePhase? phase, double? progress}) =>
      HeroBackGesture(
        kind: kind,
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
        fromLeftEdge: fromLeftEdge,
      );
}
