import 'dart:ui';

import 'package:flutter/foundation.dart';

/// A ring spreading from [center] (landing splash, tap), [progress] 0 → 1.
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

  /// A landing ring lies flat on the ground (an ellipse); a tap ring is a
  /// circle.
  final bool ground;
}

/// Everything that moves in one frame of the splash, already eased. A
/// choreography turns the clock into a frame; the painter draws it.
@immutable
class SplashFrame {
  const SplashFrame({
    required this.cartCenter,
    required this.cartUnit,
    this.squash = 0,
    this.lift = 0,
    this.speedLines = 0,
    this.letters = const <double>[],
    this.swoosh = 0,
    this.stripes = 0,
    this.leaf = 0,
    this.burst = 0,
    this.groceries = const <double>[],
    this.ambient = 0,
    this.glowCenter,
    this.ripples = const <SplashRipple>[],
    this.confetti = 0,
    this.confettiOrigin,
    this.shine = 0,
    this.ms = 0,
  });

  /// Screen centre of the cart's painted bounds.
  final Offset cartCenter;

  /// Cart size: dp per cart design unit.
  final double cartUnit;

  /// Positive = flattened (wider, shorter), negative = stretched tall; the
  /// wheels stay on the ground.
  final double squash;

  /// Hop height of the cart above its resting place, in cart design units.
  final double lift;

  /// Streaks trailing the moving cart, 0 (none) → 1 (longest).
  final double speedLines;

  /// Reveal of each letter of "ameıaMart" (may overshoot 1 while springing).
  final List<double> letters;

  /// Swoosh drawn from the left, 0 → 1.
  final double swoosh;

  /// Yellow bands on the swoosh, 0 → 1 (may overshoot).
  final double stripes;

  /// Leaf grown from its stalk, 0 → 1 (may overshoot).
  final double leaf;

  /// White disc spreading from the cart, 0 → 1 of the screen.
  final double burst;

  /// Drop of each grocery into the basket; 1 = resting inside, 0 = not
  /// shown yet. Empty = no groceries.
  final List<double> groceries;

  /// Living colour behind the logo (glow + drifting aurora), 0 → 1. Zero on
  /// the launch frame so it matches the flat native splash.
  final double ambient;

  /// Where the soft glow sits; `null` = the screen centre.
  final Offset? glowCenter;

  /// Rings spreading from landings.
  final List<SplashRipple> ripples;

  /// Celebration burst from [confettiOrigin] when the cart lands in its
  /// slot, 0 (not yet) → 1 (settled and faded).
  final double confetti;
  final Offset? confettiOrigin;

  /// Light sweep across the finished name, 0 → 1.
  final double shine;

  /// Milliseconds into the run (drives the aurora's drift).
  final double ms;

  /// This frame with a touch reaction layered on: the cart's extra
  /// [lift] / [squash] and the tap [ripples].
  SplashFrame withTouch({
    double lift = 0,
    double squash = 0,
    List<SplashRipple> ripples = const <SplashRipple>[],
  }) => SplashFrame(
    cartCenter: cartCenter,
    cartUnit: cartUnit,
    squash: this.squash + squash,
    lift: this.lift + lift,
    speedLines: speedLines,
    letters: letters,
    swoosh: swoosh,
    stripes: stripes,
    leaf: leaf,
    burst: burst,
    groceries: groceries,
    ambient: ambient,
    glowCenter: glowCenter,
    ripples: [...this.ripples, ...ripples],
    confetti: confetti,
    confettiOrigin: confettiOrigin,
    shine: shine,
    ms: ms,
  );
}
