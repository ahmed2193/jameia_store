import 'package:flutter/animation.dart';

import '../../../../core/motion/motion.dart';
import 'splash_assembly.dart';
import 'splash_beat.dart';
import 'splash_choreography.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';

/// talabat's classic intro, in JameiaMart green: the cart crouches, hops,
/// then glides left to become the "J" while the name springs up beside it.
class SplashWordmarkChoreography extends SplashChoreography {
  const SplashWordmarkChoreography();

  static const double crouchLength = 140;
  static const double crouchSquash = 0.07;
  static const double hopStart = 140;
  static const double hopLength = 420;
  static const double hopHeight = 16;
  static const double hopStretch = 0.05;
  static const double landingLength = 150;
  static const double landingSquash = 0.05;

  /// The hop's landing ring is a little softer than the final one.
  static const double hopRippleStrength = 0.7;
  static const SplashAssembly assembly = SplashAssembly(600);

  @override
  Duration get duration => AppMotion.splashWordmark;

  @override
  Interval get tagline =>
      assembly.taglineOf(duration.inMilliseconds.toDouble());

  @override
  SplashFrame frameAt(double ms, SplashLayout layout) {
    final crouch =
        crouchSquash *
        SplashBeat.span(ms, 0, crouchLength, AppMotion.signature);
    final hop = SplashBeat.span(ms, hopStart, hopLength);
    final hopArc = SplashBeat.arc(ms, hopStart, hopLength);
    final landed = hopStart + hopLength;
    final landing = landingSquash * SplashBeat.arc(ms, landed, landingLength);
    final ring = SplashBeat.span(ms, landed, SplashAssembly.rippleLength);
    return assembly.frameAt(
      ms,
      layout,
      fromCenter: layout.nativeCartCenter,
      fromUnit: SplashLayout.nativeUnit,
      squash: crouch * (1 - hop) - hopStretch * hopArc + landing,
      lift: hopHeight * hopArc,
      ripples: [
        if (ring > 0 && ring < 1)
          SplashRipple(
            layout.nativeCartGround,
            ring,
            strength: hopRippleStrength,
          ),
      ],
    );
  }
}
