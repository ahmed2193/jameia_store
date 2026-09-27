import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../../core/design/hero_mark.dart';
import '../../../../core/motion/motion.dart';
import 'splash_beat.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_wordmark.dart';

/// The part every splash ends with: the hero's flight. The bag crouches and
/// takes off (a dust ring where it stood), swoops up and round with its cape
/// whipping, arrives with a ring in the air and a pulse of light, then
/// delivers the name: each piece pops out of the bag's opening and arcs down
/// into place, the bag bobbing as it throws. Confetti once the name is
/// complete, a light sweeps the lockup, the tagline fades in and the bag
/// floats with its cape rippling until the app takes over. Times are
/// milliseconds after [start].
class SplashAssembly {
  const SplashAssembly(this.start);

  final double start;

  /// The colour glow fades in from the start of the run (not of the
  /// assembly), so the launch frame itself stays flat.
  static const double ambientLength = 520;

  // ── Crouch and take-off ────────────────────────────────────────────────────
  static const double crouchLength = 130;
  static const double crouchSquash = 0.08;
  static const double takeOff = 130;
  static const double flightLength = 520;

  /// Stretch as it leaves the ground, and how long it takes to spring back.
  static const double takeOffStretch = 0.1;
  static const double stretchLength = 240;

  /// The flight swoops this far forward (right) and up (dp) at its middle,
  /// on its way to the lockup, tipping back by [flightLean] as it climbs.
  static const double flightSwing = 36;
  static const double flightRise = 64;
  static const double flightLean = -0.16;
  static const double speedLinesLength = 380;

  // ── Arrival ────────────────────────────────────────────────────────────────
  static const double arrivalLength = 170;
  static const double arrivalSquash = 0.06;
  static const double arrivalRingStrength = 0.9;
  static const double glowPulseLength = 700;
  static const double rippleLength = 760;

  // ── Cape ───────────────────────────────────────────────────────────────────
  /// The cape's wave travels this fast at rest (radians per ms); the flight
  /// adds [flightCapeSpin] radians of travel, [flightCapeWave] units of wave
  /// and shows up to [flightCapeFold] of its underside.
  static const double idleCapeSpeed = 2 * math.pi / 1500;
  static const double flightCapeSpin = 4 * math.pi;
  static const double flightCapeWave = 5;
  static const double flightCapeFold = 0.85;
  static const double capeSettle = 260;

  // ── Deliveries ─────────────────────────────────────────────────────────────
  static const double firstDelivery = 690;
  static const double deliveryLength = 420;
  static const double landingLength = 160;
  static const double landingSquash = 0.14;

  /// The bag bobs by this much (design units) and its cape flicks as it
  /// throws each piece.
  static const double recoilLift = 3;
  static const double recoilLength = 220;
  static const double recoilWave = 1.5;

  // ── Finale ─────────────────────────────────────────────────────────────────
  static const double confettiDelay = 20;
  static const double confettiLength = 950;

  /// The light sweep starts this long before the last piece lands.
  static const double shineLead = 60;
  static const double shineLength = 560;
  static const double taglineLength = 420;

  /// Once arrived the bag floats: this high (design units), this slowly
  /// (ms per bob), easing in over [floatRamp].
  static const double floatHeight = 1.6;
  static const double floatPeriod = 1700;
  static const double floatRamp = 300;

  static double get arrival => takeOff + flightLength;

  /// When the bag throws piece [index] of [wordmark].
  static double launchOf(SplashWordmark wordmark, int index) =>
      firstDelivery + index * wordmark.stagger;

  /// When the last piece of [wordmark] is in place (after [start]).
  static double lastLanding(SplashWordmark wordmark) =>
      launchOf(wordmark, wordmark.pieces.length - 1) + deliveryLength;

  /// When everything has settled (tagline in, light sweep done).
  double end(SplashWordmark wordmark) {
    final landed = lastLanding(wordmark);
    return start +
        math.max(landed + taglineLength, landed - shineLead + shineLength);
  }

  /// Tagline beat as a fraction of a run of [total] ms.
  Interval taglineOf(SplashWordmark wordmark, double total) {
    final landed = start + lastLanding(wordmark);
    return Interval(
      landed / total,
      (landed + taglineLength) / total,
      curve: AppMotion.signature,
    );
  }

  /// The frame at [ms] for a mark that was at [fromCenter] / [fromUnit] with
  /// [squash], [lift] and extra [capeWave] from the prelude when the
  /// assembly began; [ripples] adds the prelude's own rings.
  SplashFrame frameAt(
    double ms,
    SplashLayout layout, {
    required Offset fromCenter,
    required double fromUnit,
    double squash = 0,
    double lift = 0,
    double capeWave = 0,
    double burst = 0,
    List<double> groceries = const <double>[],
    List<SplashRipple> ripples = const <SplashRipple>[],
  }) {
    final t = ms - start;
    final wordmark = layout.wordmark;

    // Crouch, then leave the ground and swoop into the lockup.
    final crouch =
        crouchSquash *
        SplashBeat.span(t, 0, crouchLength, AppMotion.signature) *
        (1 - SplashBeat.span(t, takeOff, stretchLength / 4));
    final fly = SplashBeat.span(
      t,
      takeOff,
      flightLength,
      AppMotion.emphasizedDecelerate,
    );
    final swoop = math.sin(math.pi * fly);
    final center =
        SplashBeat.offset(fromCenter, layout.markCenter, fly) +
        Offset(flightSwing, -flightRise) * swoop;
    final flightArc = SplashBeat.arc(t, takeOff, flightLength);
    final capeArc = SplashBeat.arc(t, takeOff, flightLength + capeSettle);

    // Deliveries, and the bob and flick each throw gives the bag.
    final deliveries = <SplashDelivery>[];
    var recoil = 0.0;
    for (var i = 0; i < wordmark.pieces.length; i++) {
      final launch = launchOf(wordmark, i);
      if (t < launch) break;
      deliveries.add((
        flight: SplashBeat.span(t, launch, deliveryLength),
        squash:
            landingSquash *
            SplashBeat.arc(t, launch + deliveryLength, landingLength),
      ));
      recoil += SplashBeat.arc(t, launch, recoilLength);
    }
    final floating =
        floatHeight *
        math.sin(2 * math.pi * (t - arrival) / floatPeriod) *
        SplashBeat.span(t, arrival + capeSettle / 2, floatRamp);

    final landed = lastLanding(wordmark);
    final arrived = SplashBeat.span(t, arrival, rippleLength);
    final takingOff = SplashBeat.span(t, takeOff, rippleLength);
    return SplashFrame(
      markCenter: center,
      markUnit: SplashBeat.lerp(fromUnit, layout.markUnit, fly),
      squash:
          squash +
          crouch -
          takeOffStretch * SplashBeat.arc(t, takeOff, stretchLength) +
          arrivalSquash * SplashBeat.arc(t, arrival - 40, arrivalLength),
      lift: lift + recoilLift * recoil + floating,
      lean: flightLean * flightArc,
      capeWave:
          HeroMark.restWave +
          capeWave +
          flightCapeWave * capeArc +
          recoilWave * recoil,
      capePhase:
          HeroMark.restPhase +
          idleCapeSpeed * ms +
          flightCapeSpin *
              SplashBeat.span(t, takeOff, flightLength + capeSettle),
      capeFold: flightCapeFold * capeArc,
      speedLines: SplashBeat.arc(t, takeOff, speedLinesLength),
      deliveries: deliveries,
      burst: burst,
      groceries: groceries,
      ambient: SplashBeat.span(ms, 0, ambientLength, AppMotion.signature),
      glowCenter: SplashBeat.offset(
        layout.center,
        layout.lockupBounds.center,
        fly,
      ),
      glowPulse: SplashBeat.arc(t, arrival - 60, glowPulseLength),
      ripples: <SplashRipple>[
        ...ripples,
        if (takingOff > 0 && takingOff < 1)
          SplashRipple(layout.nativeGround, takingOff),
        if (arrived > 0 && arrived < 1)
          SplashRipple(
            layout.markCenter,
            arrived,
            strength: arrivalRingStrength,
            ground: false,
          ),
      ],
      confetti: SplashBeat.span(t, landed + confettiDelay, confettiLength),
      confettiOrigin: layout.wordCenter,
      shine: SplashBeat.span(
        t,
        landed - shineLead,
        shineLength,
        AppMotion.machEaseInOut,
      ),
      ms: ms,
    );
  }
}
