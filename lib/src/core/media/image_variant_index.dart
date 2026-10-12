import 'package:flutter/foundation.dart' show visibleForTesting;

import 'image_key_policy.dart';

/// Per asset ([assetId]), the CDN variants this process has built, so a site
/// that needs one size can find a variant of the same asset to show meanwhile
/// (the load-source probe, `ImageLoadPolicy`). Whether a file is on disk is
/// `ImageDiskIndex`'s job, not this index's.
///
/// Process-wide [instance] (a static singleton, never in get_it). Bounded:
/// past [maxAssets] assets it starts over (like the URL memos); past
/// [maxPerAsset] variants an asset drops its oldest one.
class ImageVariantIndex {
  ImageVariantIndex({this.maxAssets = 4096, this.maxPerAsset = 8});

  static final ImageVariantIndex instance = ImageVariantIndex();

  final int maxAssets;
  final int maxPerAsset;

  final Map<String, List<ImageVariant>> _byAsset =
      <String, List<ImageVariant>>{};
  int _count = 0;

  /// Variants recorded, over all assets.
  int get count => _count;

  /// Records [variant] for [assetId].
  ///
  /// The image widget's variant memo calls this once per NEW variant, not per
  /// build. A repeat call with the same (or an equal) variant is one map
  /// lookup and an identity check — no allocation beyond a new record.
  void record(String assetId, ImageVariant variant) {
    List<ImageVariant>? list = _byAsset[assetId];
    if (list == null) {
      if (_byAsset.length >= maxAssets) clear();
      _byAsset[assetId] = list = <ImageVariant>[];
    }
    if (!_contains(list, variant)) {
      if (list.length >= maxPerAsset) {
        list.removeAt(0);
        _count--;
      }
      list.add(variant);
      _count++;
    }
  }

  /// Every recorded variant of [assetId], oldest first.
  List<ImageVariant> variantsOf(String assetId) =>
      List<ImageVariant>.unmodifiable(
        _byAsset[assetId] ?? const <ImageVariant>[],
      );

  /// The narrowest variant with `wireW >= w` that passes [where], else the
  /// widest with `wireW < w` that does: a larger variant is already decoded
  /// and downscales sharply, a smaller one upscales blurry. One pass, and
  /// [where] (the caller's RAM probe) runs only for a variant that would
  /// improve the answer. Width-less variants are skipped, and so is a smaller
  /// one narrower than [minWidth] (the caller's fidelity floor).
  ImageVariant? nearestWhere(
    String assetId,
    int w,
    bool Function(ImageVariant v) where, {
    int minWidth = 0,
  }) {
    ImageVariant? above, below;
    for (final ImageVariant v in _byAsset[assetId] ?? const <ImageVariant>[]) {
      final int? vw = v.wireW;
      if (vw == null) continue;
      final bool isAbove = vw >= w;
      // A smaller variant never beats one already found at or above [w], and
      // one under the floor would upscale too far to stand in at all.
      if (!isAbove && (above != null || vw < minWidth)) continue;
      final ImageVariant? best = isAbove ? above : below;
      if (best != null && (isAbove ? vw >= best.wireW! : vw <= best.wireW!)) {
        continue;
      }
      if (!where(v)) continue;
      if (isAbove) {
        above = v;
      } else {
        below = v;
      }
    }
    return above ?? below;
  }

  /// Forgets every variant (the disk cache was emptied:
  /// `HeroImageCacheManager.clearCache`).
  void clear() {
    _byAsset.clear();
    _count = 0;
  }

  @visibleForTesting
  void reset() => clear();

  static bool _contains(List<ImageVariant> list, ImageVariant v) {
    for (final ImageVariant e in list) {
      if (identical(e, v) || e == v) return true;
    }
    return false;
  }
}
