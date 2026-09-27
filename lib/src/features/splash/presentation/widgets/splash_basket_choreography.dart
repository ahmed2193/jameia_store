import 'package:flutter/animation.dart';

import '../../../../core/motion/motion.dart';
import 'splash_assembly.dart';
import 'splash_beat.dart';
import 'splash_choreography.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';

/// The mart intro: a bottle, an orange and some greens drop into the basket
/// one after another — the cart dips under each — then the full cart glides
/// into the "J" of the name.
class SplashBasketChoreography extends SplashChoreography {
  const SplashBasketChoreography();

  static const int groceryCount = 3;
  static const double firstDrop = 80;
  static const double dropStagger = 170;
  static const double fallLength = 320;
  static const double bounceLength = 160;

  /// How far back up an item bounces, as a share of its fall.
  static const double bounceHeight = 0.1;
  static const double landingLength = 150;
  static const double landingSquash = 0.06;
  static const SplashAssembly assembly = SplashAssembly(880);

  @override
  Duration get duration => AppMotion.splashBasket;

  @override
  Interval get tagline =>
      assembly.taglineOf(duration.inMilliseconds.toDouble());

  @override
  SplashFrame frameAt(double ms, SplashLayout layout) {
    var squash = 0.0;
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
      squash += landingSquash * SplashBeat.arc(ms, landed, landingLength);
    }
    return assembly.frameAt(
      ms,
      layout,
      fromCenter: layout.nativeCartCenter,
      fromUnit: SplashLayout.nativeUnit,
      squash: squash,
      groceries: groceries,
    );
  }
}
