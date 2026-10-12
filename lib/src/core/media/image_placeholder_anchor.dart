import 'package:flutter/foundation.dart' show visibleForTesting;

/// The monotonic time an image placeholder's shimmer deadline is measured
/// on: ONE process-wide [Stopwatch], started on first read, so a read
/// allocates nothing.
abstract final class ImagePlaceholderClock {
  static final Stopwatch _watch = Stopwatch()..start();

  /// Microseconds since the first read.
  static int get nowUs => debugNowUs?.call() ?? _watch.elapsedMicroseconds;

  /// Test seam: the fake-async clock, so deadlines follow `tester.pump`.
  @visibleForTesting
  static int Function()? debugNowUs;

  /// What is left of a deadline at [deadlineUs]: zero once it has passed.
  static Duration leftUntil(int deadlineUs) {
    final int left = deadlineUs - nowUs;
    return left > 0 ? Duration(microseconds: left) : Duration.zero;
  }
}

/// When an image tile's placeholder was FIRST painted ([atUs] on
/// [ImagePlaceholderClock]; null until its first frame ends): the one instant
/// the shimmer delay counts from. The tile owns it and hands it to every
/// delayed shimmer it builds — octo_image remounts the placeholder inside its
/// fade-out stack the moment the image lands, and a fresh full delay there
/// would snap a running shimmer back to the still box. The first delayed
/// shimmer whose frame ends sets it; a remount reads it and carries on.
///
/// Counted from the first painted frame, not from mount: a cold start's
/// first frame can land over a second after the first screen mounts, and a
/// deadline counted from mount would be spent before anything was painted
/// (reference `FINAL_REPORT.md` §8, "S7 cold start").
class ImagePlaceholderAnchor {
  int? atUs;

  /// What is left of [delay] counted from [atUs]: zero once passed, null
  /// while no frame has painted the placeholder yet (the delay has not
  /// started).
  Duration? left(Duration delay) {
    final int? at = atUs;
    return at == null
        ? null
        : ImagePlaceholderClock.leftUntil(at + delay.inMicroseconds);
  }
}
