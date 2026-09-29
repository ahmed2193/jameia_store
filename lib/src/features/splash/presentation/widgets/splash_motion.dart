/// The splash's own motion tokens (feature-local: nothing outside the splash
/// times itself by them). One-shot runs from the launch-screen frame to the
/// hand-off, gated by `MotionGuard`. The reference intro is ~2 s of logo
/// motion on the brand colour; these stay in that range. [INFERENCE] —
/// design choices.
abstract final class SplashMotion {
  /// The bag takes off, swoops up and delivers the name under it.
  static const Duration wordmark = Duration(milliseconds: 2000);

  /// Groceries drop into the bag before it takes off.
  static const Duration basket = Duration(milliseconds: 2550);

  /// A white disc bursts out of the bag into the full-colour logo on white.
  static const Duration burst = Duration(milliseconds: 2250);

  /// Reduced motion: how long the finished logo stays before the hand-off.
  static const Duration reducedHold = Duration(milliseconds: 700);

  /// The launch frame stays still this long after it reached the screen, so
  /// the OS splash's exit cross-fade ends on an identical picture before
  /// anything moves.
  static const Duration handOffHold = Duration(milliseconds: 250);

  /// Longest wait for the engine to report the first rasterized frame before
  /// the intro starts anyway (test bindings never report frame timings).
  static const Duration firstFrameWait = Duration(milliseconds: 600);

  /// A ring of colour spreading from a finger on the splash.
  static const Duration tapRipple = Duration(milliseconds: 700);

  /// The bag's happy hop (and cape flick) when it is tapped on the splash.
  static const Duration markHop = Duration(milliseconds: 520);
}
