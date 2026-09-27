import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../../core/motion/motion.dart';
import 'splash_beat.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_wordmark_glyphs.dart';

/// The part every splash ends with: the cart glides into the "J" slot and
/// lands (a ring and a confetti burst), the letters spring up one by one,
/// the swoosh draws, the leaf grows, a light sweeps the name and the tagline
/// fades in — over a living colour glow. Times are milliseconds after
/// [start].
class SplashAssembly {
  const SplashAssembly(this.start);

  final double start;

  /// The colour glow fades in from the start of the run (not of the
  /// assembly), so the launch frame itself stays flat.
  static const double ambientLength = 520;
  static const double moveLength = 460;
  static const double speedLinesStart = 40;
  static const double speedLinesLength = 320;
  static const double landingStart = 430;
  static const double landingLength = 170;
  static const double landingSquash = 0.06;
  static const double rippleLength = 760;
  static const double confettiDelay = 40;
  static const double confettiLength = 950;
  static const double lettersStart = 240;
  static const double letterStagger = 45;
  static const double letterLength = 380;
  static const double swooshStart = 560;
  static const double swooshLength = 380;
  static const double stripesStart = 860;
  static const double stripesLength = 260;
  static const double leafStart = 660;
  static const double leafLength = 420;
  static const double shineStart = 860;
  static const double shineLength = 520;
  static const double taglineStart = 760;
  static const double taglineLength = 400;

  /// When everything has settled (tagline in, light sweep done).
  double get end =>
      start + math.max(taglineStart + taglineLength, shineStart + shineLength);

  /// Tagline beat as a fraction of a run of [total] ms.
  Interval taglineOf(double total) => Interval(
    (start + taglineStart) / total,
    (start + taglineStart + taglineLength) / total,
    curve: AppMotion.signature,
  );

  /// The frame at [ms] for a cart that was at [fromCenter] / [fromUnit] with
  /// [squash] and [lift] when the assembly began; [ripples] adds the
  /// prelude's own rings.
  SplashFrame frameAt(
    double ms,
    SplashLayout layout, {
    required Offset fromCenter,
    required double fromUnit,
    double squash = 0,
    double lift = 0,
    double burst = 0,
    List<double> groceries = const <double>[],
    List<SplashRipple> ripples = const <SplashRipple>[],
  }) {
    final t = ms - start;
    final move = SplashBeat.span(t, 0, moveLength, AppMotion.machEaseInOut);
    final landing = SplashBeat.span(t, landingStart, rippleLength);
    return SplashFrame(
      cartCenter: SplashBeat.offset(fromCenter, layout.lockupCartCenter, move),
      cartUnit: SplashBeat.lerp(fromUnit, layout.lockupCartUnit, move),
      squash:
          squash +
          landingSquash * SplashBeat.arc(t, landingStart, landingLength),
      lift: lift,
      speedLines: SplashBeat.arc(t, speedLinesStart, speedLinesLength),
      letters: <double>[
        for (var i = 0; i < SplashWordmarkGlyphs.letters.length; i++)
          SplashBeat.span(
            t,
            lettersStart + i * letterStagger,
            letterLength,
            AppMotion.emphasized,
          ),
      ],
      swoosh: SplashBeat.span(
        t,
        swooshStart,
        swooshLength,
        AppMotion.signature,
      ),
      stripes: SplashBeat.span(
        t,
        stripesStart,
        stripesLength,
        AppMotion.emphasized,
      ),
      leaf: SplashBeat.span(t, leafStart, leafLength, AppMotion.emphasized),
      burst: burst,
      groceries: groceries,
      ambient: SplashBeat.span(ms, 0, ambientLength, AppMotion.signature),
      glowCenter: SplashBeat.offset(layout.center, layout.lockupCenter, move),
      ripples: <SplashRipple>[
        ...ripples,
        if (landing > 0 && landing < 1)
          SplashRipple(layout.lockupCartGround, landing),
      ],
      confetti: SplashBeat.span(
        t,
        landingStart + confettiDelay,
        confettiLength,
      ),
      confettiOrigin: layout.lockupCartCenter,
      shine: SplashBeat.span(
        t,
        shineStart,
        shineLength,
        AppMotion.machEaseInOut,
      ),
      ms: ms,
    );
  }
}
