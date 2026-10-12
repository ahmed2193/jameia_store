import 'package:flutter/foundation.dart';

/// The identity of `HeroRetryingImage`'s inner `CachedNetworkImage`: the
/// raw-fallback bit, the attempt above it and the remount epoch above that
/// (an epoch bump comes with attempt 0). A new attempt is a fresh load
/// (memory → disk → network); the same key keeps octo_image's element for
/// its gapless path. Its own type, so it never equals a plain
/// `ValueKey<int>` a screen puts nearby.
class HeroImageAttemptKey extends ValueKey<int> {
  const HeroImageAttemptKey({
    required int epoch,
    required int attempt,
    required bool raw,
  }) : super(
         (epoch << _epochShift) | (attempt << _attemptShift) | (raw ? 1 : 0),
       );

  static const int _attemptShift = 1;
  static const int _epochShift = 21;
}
