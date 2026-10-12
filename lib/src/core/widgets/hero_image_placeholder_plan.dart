import 'package:flutter/painting.dart' show ImageProvider;
import 'package:flutter/foundation.dart' show immutable;

import '../media/image_placeholder_anchor.dart';

/// Which loading look an image tile shows (`HeroImageLoadingPlaceholder`).
enum HeroImageLoadingLook {
  /// The still box: a disk load, or the underlay of an image already there.
  still,

  /// The still box, turning into the shimmer [HeroImagePlaceholderPlan.delay]
  /// after the tile's first painted frame (a first attempt).
  quiet,

  /// The shimmer at once (a retry, a failure).
  shimmer,

  /// Another size of the image, cached in RAM (the fidelity floor).
  variant,
}

/// What the retrying image hands its placeholder slot: the look and what it
/// needs. A value, so the tile's decision logic returns a plan and the one
/// widget that renders it stays the same element while the look holds.
@immutable
class HeroImagePlaceholderPlan {
  const HeroImagePlaceholderPlan.still()
    : look = HeroImageLoadingLook.still,
      delay = Duration.zero,
      anchor = null,
      animate = false,
      image = null;

  const HeroImagePlaceholderPlan.quiet(
    this.delay,
    ImagePlaceholderAnchor this.anchor,
  ) : look = HeroImageLoadingLook.quiet,
      animate = true,
      image = null;

  const HeroImagePlaceholderPlan.shimmer({required this.animate})
    : look = HeroImageLoadingLook.shimmer,
      delay = Duration.zero,
      anchor = null,
      image = null;

  const HeroImagePlaceholderPlan.variant(ImageProvider<Object> this.image)
    : look = HeroImageLoadingLook.variant,
      delay = Duration.zero,
      anchor = null,
      animate = false;

  final HeroImageLoadingLook look;

  /// [HeroImageLoadingLook.quiet]: the wait before the shimmer, counted from
  /// [anchor].
  final Duration delay;
  final ImagePlaceholderAnchor? anchor;

  /// [HeroImageLoadingLook.shimmer]: false freezes it on its still frame.
  final bool animate;

  /// [HeroImageLoadingLook.variant]: the cached other size.
  final ImageProvider<Object>? image;
}
