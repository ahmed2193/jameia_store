import 'package:flutter/animation.dart';

import '../../../../core/motion/motion.dart';
import 'splash_assembly.dart';
import 'splash_beat.dart';
import 'splash_choreography.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_wordmark.dart';

/// The mart intro: a bottle, an orange and some greens drop into the bag one
/// after another (it dips and its cape flicks under each), then the full bag
/// takes off and delivers the name.
class SplashBasketChoreography extends SplashChoreography {
  const SplashBasketChoreography();

  static const int groceryCount = 3;
  static const double firstDrop = 40;
  static const double dropStagger = 110;
  static const double fallLength = 280;
  static const double bounceLength = 160;

  /// How far back up an item bounces, as a share of its fall.
  static const double bounceHeight = 0.1;
  static const double landingLength = 150;
  static const double landingSquash = 0.06;
  static const double landingWave = 2;
  static const SplashAssembly assembly = SplashAssembly(540);

  @override
  Duration get duration => AppMotion.splashBasket;

  @override
  Interval tagline(SplashWordmark wordmark) =>
      assembly.taglineOf(wordmark, duration.inMilliseconds.toDouble());

  @override
  SplashFrame frameAt(double ms, SplashLayout layout) {
    var squash = 0.0;
    var wave = 0.0;
    final groceries = <double>[];
    for (var i = 0; i < groceryCount; i++) {
      final dropStart = firstDrop + i * dropStagger;
      final landed = dropStart + fallLength;
      final fall = SplashBeat.span(ms, dropStart, fallLength, AppMotion.exit);
      groceries.add(
        ms < dropStart
            ? 0
            : fall - bounceHeight * SplashBeat.arc(ms, landed, bounceLength),
      );
      final dip = SplashBeat.arc(ms, landed, landingLength);
      squash += landingSquash * dip;
      wave += landingWave * dip;
    }
    return assembly.frameAt(
      ms,
      layout,
      fromCenter: layout.nativeMarkCenter,
      fromUnit: SplashLayout.nativeUnit,
      squash: squash,
      capeWave: wave,
      groceries: groceries,
    );
  }
}
