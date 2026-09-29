import 'package:flutter/animation.dart';

import '../../../../core/motion/motion.dart';
import 'splash_assembly.dart';
import 'splash_beat.dart';
import 'splash_choreography.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_motion.dart';
import 'splash_palette.dart';
import 'splash_wordmark.dart';

/// The reveal intro: the bag breathes in, then a white disc bursts out of it
/// and repaints the screen as the full-colour logo on white — the colour of
/// the home screen that follows — while the bag takes off and delivers the
/// name.
class SplashBurstChoreography extends SplashChoreography {
  const SplashBurstChoreography();

  static const double breathLength = 200;
  static const double breathDepth = 0.08;
  static const double popLength = 280;
  static const double burstStart = 200;
  static const double burstLength = 460;
  static const SplashAssembly assembly = SplashAssembly(260);

  /// The disc reaches the screen corners at the end of its run; by this
  /// share it has covered the status bar but for the corner pixels.
  static const double statusBarCovered = 0.9;

  @override
  Duration get duration => SplashMotion.burst;

  @override
  Interval tagline(SplashWordmark wordmark) =>
      assembly.taglineOf(wordmark, duration.inMilliseconds.toDouble());

  @override
  SplashPalette get endPalette => SplashPalette.onWhite;

  @override
  bool isBrandTopAt(double ms) =>
      SplashBeat.span(ms, burstStart, burstLength, AppMotion.machEaseInOut) <
      statusBarCovered;

  @override
  SplashFrame frameAt(double ms, SplashLayout layout) {
    final breath =
        1 -
        breathDepth *
            SplashBeat.span(ms, 0, breathLength, AppMotion.signature) +
        breathDepth *
            SplashBeat.span(ms, breathLength, popLength, AppSprings.snappy);
    return assembly.frameAt(
      ms,
      layout,
      fromCenter: layout.nativeMarkCenter,
      fromUnit: SplashLayout.nativeUnit * breath,
      burst: SplashBeat.span(
        ms,
        burstStart,
        burstLength,
        AppMotion.machEaseInOut,
      ),
      total: duration.inMilliseconds.toDouble(),
    );
  }
}
