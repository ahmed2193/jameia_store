/// How long the brand backdrop's spread has been turning, shared by every
/// backdrop on screen: a header handed from one page to the next (the phone
/// step → the code step) keeps turning from where it was instead of starting
/// over, and two backdrops ticking in the same frame move it once.
///
/// Only running time counts: a frame gap longer than [maxStep] (the backdrop
/// was paused, covered or off screen) is skipped, so the spread never jumps.
abstract final class BrandBackdropClock {
  /// Longest gap between two frames that still counts as running time.
  static const Duration maxStep = Duration(milliseconds: 100);

  static Duration _elapsed = Duration.zero;
  static Duration? _lastFrame;

  static Duration get elapsed => _elapsed;

  /// Moves the clock to [frame] (the frame's time stamp) and returns the
  /// running time so far.
  static Duration advance(Duration frame) {
    final last = _lastFrame;
    _lastFrame = frame;
    if (last == null || frame <= last) return _elapsed;
    final step = frame - last;
    if (step <= maxStep) _elapsed += step;
    return _elapsed;
  }
}
