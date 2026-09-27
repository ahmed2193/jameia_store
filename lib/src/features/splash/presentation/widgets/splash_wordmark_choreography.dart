import 'package:flutter/animation.dart';

import '../../../../core/motion/motion.dart';
import 'splash_assembly.dart';
import 'splash_choreography.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_wordmark.dart';

/// The hero intro, white on Hero green: straight from the launch frame the
/// bag crouches, takes off and swoops up, then delivers the name piece by
/// piece under it.
class SplashWordmarkChoreography extends SplashChoreography {
  const SplashWordmarkChoreography();

  static const SplashAssembly assembly = SplashAssembly(0);

  @override
  Duration get duration => AppMotion.splashWordmark;

  @override
  Interval tagline(SplashWordmark wordmark) =>
      assembly.taglineOf(wordmark, duration.inMilliseconds.toDouble());

  @override
  SplashFrame frameAt(double ms, SplashLayout layout) => assembly.frameAt(
    ms,
    layout,
    fromCenter: layout.nativeMarkCenter,
    fromUnit: SplashLayout.nativeUnit,
  );
}
