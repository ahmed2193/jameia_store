import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart' show ImageProvider;

import 'image_load_policy.dart';

/// Where an image load will come from, as far as a synchronous probe can
/// tell when the tile mounts (`ImageLoadPolicy.decide`).
enum ImageLoadSource {
  /// The exact RAM key is complete: octo_image paints in the first frame with
  /// no placeholder and no fade.
  ram,

  /// The file is known to be on disk: a still box, no shimmer, no fade.
  disk,

  /// Another size of the same asset is complete in RAM: it paints in the box
  /// as the placeholder until the right size decodes. No shimmer, no fade.
  variant,

  /// Unknown: the still box, then the shimmer, and the fade.
  network,
}

/// One mount's transition plan (the Kingfisher rule: only a network load
/// animates). Taken once per mount / cacheKey and kept by the tile, so the
/// placeholder never changes shape mid-load.
@immutable
class ImageLoadDecision {
  const ImageLoadDecision._(
    this.source, {
    this.placeholderProvider,
    this.placeholderRamKey,
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
    this.shimmerDelay = ImageLoadPolicy.networkShimmerDelay,
  });

  static const ImageLoadDecision ram = ImageLoadDecision._(ImageLoadSource.ram);

  static const ImageLoadDecision disk = ImageLoadDecision._(
    ImageLoadSource.disk,
    shimmerDelay: ImageLoadPolicy.diskShimmerDelay,
  );

  factory ImageLoadDecision.variant(
    ImageProvider<Object> cached,
    Object cachedRamKey,
  ) => ImageLoadDecision._(
    ImageLoadSource.variant,
    placeholderProvider: cached,
    placeholderRamKey: cachedRamKey,
  );

  factory ImageLoadDecision.network({
    required Duration fadeIn,
    required Duration fadeOut,
  }) => ImageLoadDecision._(
    ImageLoadSource.network,
    fadeIn: fadeIn,
    fadeOut: fadeOut,
  );

  final ImageLoadSource source;

  /// [ImageLoadSource.variant] only: the cached other-size provider, built
  /// exactly as the package builds it, so resolving it is a sync RAM hit.
  final ImageProvider<Object>? placeholderProvider;

  /// [ImageLoadSource.variant] only: the ImageCache key of
  /// [placeholderProvider], so a failing tile can re-check that the cached
  /// variant is still complete in RAM before it keeps showing it.
  final Object? placeholderRamKey;

  /// octo_image's image fade-in / placeholder fade-out for this load.
  final Duration fadeIn;
  final Duration fadeOut;

  /// How long the still placeholder waits before it turns into the shimmer.
  /// Unused by [ImageLoadSource.variant].
  final Duration shimmerDelay;
}
