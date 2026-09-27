import 'package:flutter/animation.dart';

import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_palette.dart';
import 'splash_wordmark.dart';

/// One way the splash can play. Every choreography starts on the launch
/// screen's frame (the mark centred at [SplashLayout.nativeUnit]) so the
/// hand-over from the OS splash is seamless, and ends on the finished lockup.
abstract class SplashChoreography {
  const SplashChoreography();

  /// Whole run, from the launch frame to the hand-off to the app.
  Duration get duration;

  /// When the tagline fades in under [wordmark], as a fraction of
  /// [duration].
  Interval tagline(SplashWordmark wordmark);

  /// Colours the scene ends on (the tagline and status bar follow them).
  SplashPalette get endPalette => SplashPalette.onBrand;

  /// Frame at [ms] milliseconds into the run.
  SplashFrame frameAt(double ms, SplashLayout layout);

  /// Whether the screen is still brand green under the status bar at [ms].
  bool isBrandTopAt(double ms) => true;
}
