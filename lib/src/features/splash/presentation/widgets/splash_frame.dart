import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../../core/design/hero_mark.dart';
import '../../../../core/design/hero_mark_painting.dart';

/// A ring spreading from [center] (take-off, arrival, tap), [progress] 0 → 1.
@immutable
class SplashRipple {
  const SplashRipple(
    this.center,
    this.progress, {
    this.strength = 1,
    this.ground = true,
  });

  final Offset center;
  final double progress;

  /// Size and opacity multiplier (a tap ripple is smaller than a landing).
  final double strength;

  /// A take-off ring lies flat on the ground (an ellipse); a mid-air or tap
  /// ring is a circle.
  final bool ground;
}

/// One piece of the name on its way from the bag to its place: [flight]
/// 0 (in the bag's opening) → 1 (in place), then [squash] as it lands.
typedef SplashDelivery = ({double flight, double squash});

/// Everything that moves in one frame of the splash, already eased. A
/// choreography turns the clock into a frame; the painter draws it.
@immutable
class SplashFrame {
  const SplashFrame({
    required this.markCenter,
    required this.markUnit,
    this.squash = 0,
    this.lift = 0,
    this.lean = 0,
    this.capeWave = HeroMark.restWave,
    this.capePhase = HeroMark.restPhase,
    this.capeFold = 0,
    this.speedLines = 0,
    this.deliveries = const <SplashDelivery>[],
    this.burst = 0,
    this.groceries = const <double>[],
    this.ambient = 0,
    this.glowCenter,
    this.glowPulse = 0,
    this.ripples = const <SplashRipple>[],
    this.confetti = 0,
    this.confettiOrigin,
    this.shine = 0,
    this.ms = 0,
  });

  /// Screen centre of the mark's painted bounds.
  final Offset markCenter;

  /// Mark size: dp per design unit.
  final double markUnit;

  /// Positive = flattened on its bottom edge, negative = stretched tall.
  final double squash;

  /// Height of the mark above its place, in design units.
  final double lift;

  /// Extra tilt, radians (negative tips it back, nose up).
  final double lean;

  /// The cape's travelling wave (amplitude in design units, phase in
  /// radians) and how much of its darker underside shows (0 → 1).
  final double capeWave;
  final double capePhase;
  final double capeFold;

  /// Streaks trailing the flying mark, 0 (none) → 1 (longest).
  final double speedLines;

  /// Each piece of the name the bag has sent out, in delivery order. Pieces
  /// not sent yet are missing.
  final List<SplashDelivery> deliveries;

  /// White disc spreading from the mark, 0 → 1 of the screen.
  final double burst;

  /// Drop of each grocery into the bag; 1 = resting inside, 0 = not shown
  /// yet. Empty = no groceries.
  final List<double> groceries;

  /// Living colour behind the logo (glow + drifting aurora), 0 → 1. Zero on
  /// the launch frame so it matches the flat native splash.
  final double ambient;

  /// Where the soft glow sits; `null` = the screen centre.
  final Offset? glowCenter;

  /// Extra glow as the mark arrives, 0 → 1 → 0.
  final double glowPulse;

  /// Rings spreading from take-off, arrival and taps.
  final List<SplashRipple> ripples;

  /// Celebration burst from [confettiOrigin] when the name is complete,
  /// 0 (not yet) → 1 (settled and faded).
  final double confetti;
  final Offset? confettiOrigin;

  /// Light sweep across the finished lockup, 0 → 1.
  final double shine;

  /// Milliseconds into the run (drives the aurora's drift).
  final double ms;

  /// The mark's pose in this frame.
  HeroMarkPose get pose => HeroMarkPose(
    squash: squash,
    lift: lift,
    lean: lean,
    wave: capeWave,
    phase: capePhase,
    fold: capeFold,
  );

  /// This frame with a touch reaction layered on: the mark's extra [lift],
  /// [squash] and cape [wave], and the tap [ripples].
  SplashFrame withTouch({
    double lift = 0,
    double squash = 0,
    double wave = 0,
    List<SplashRipple> ripples = const <SplashRipple>[],
  }) => SplashFrame(
    markCenter: markCenter,
    markUnit: markUnit,
    squash: this.squash + squash,
    lift: this.lift + lift,
    lean: lean,
    capeWave: capeWave + wave,
    capePhase: capePhase,
    capeFold: capeFold,
    speedLines: speedLines,
    deliveries: deliveries,
    burst: burst,
    groceries: groceries,
    ambient: ambient,
    glowCenter: glowCenter,
    glowPulse: glowPulse,
    ripples: [...this.ripples, ...ripples],
    confetti: confetti,
    confettiOrigin: confettiOrigin,
    shine: shine,
    ms: ms,
  );
}
