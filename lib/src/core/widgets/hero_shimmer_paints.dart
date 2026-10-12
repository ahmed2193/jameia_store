import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';

/// The bag mark's recolouring [Paint], ONE per tint, shared by every image
/// shimmer painter (read at paint time, never mutated): `srcIn` recolours the
/// white mask inside the image draw itself — no saveLayer, no offscreen pass
/// — and the native colour filter is made once per tint, not per painter.
/// Only a tint or two exist; the cap guards a pathological caller (painters
/// keep their own reference).
///
/// Medium filtering: the 256 px mask is drawn at 16–48 dp (≈ 32–144 px), a
/// downscale of up to 8×, which needs the mipmaps `low` skips.
abstract final class HeroShimmerPaints {
  static const int _cap = 8;
  static final Map<Color, Paint> _byTint = <Color, Paint>{};

  /// Paints held (tests only).
  @visibleForTesting
  static int get debugCount => _byTint.length;

  /// The shared paint for [tint].
  static Paint of(Color tint) {
    final Paint? cached = _byTint[tint];
    if (cached != null) return cached;
    if (_byTint.length >= _cap) _byTint.clear();
    return _byTint[tint] = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(tint, BlendMode.srcIn);
  }
}
