import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager;

import 'image_variant.dart';

// The ONE formula for the in-RAM ImageCache key a network image decodes
// under. Verified against the resolved sources (cached_network_image 4.0.0,
// octo_image 2.1.0, Flutter 3.47.4):
//
//   ResizeImageKey(CachedNetworkImageProvider[cacheKey], exact, w, h, false)
//
// `CachedNetworkImage(cacheKey:, memCacheWidth/Height:)` builds the provider
// (cached_image_widget.dart:245-255: no maxWidth/HeightDiskCache, scale 1.0)
// and hands memCacheWidth/Height to OctoImage (:293-294), which wraps it in
// `ResizeImage.resizeIfNeeded` (octo_image image.dart:205-209). The
// provider's key is itself (`obtainKey` → SynchronousFuture,
// cached_network_image_provider.dart:67-71) and its equality reads
// `cacheKey ?? url`, scale and the disk-cache max sizes only (:176-187; url,
// headers and cache manager are not part of it); `ResizeImageKey` adds the
// policy, w, h and allowUpscaling (painting/image_provider.dart:816-831).
// 4.0.0 differs from the reference's 3.4.1 only by `material_ui` imports. The
// load policy and the debug trace both read the key from here, so the probe
// and the trace can never disagree with the package.

/// The provider `CachedNetworkImage` resolves for [cacheKey] at the decode
/// size [w] x [h] (`null` = not resized). While that key is complete in RAM,
/// an `Image` built on it paints in its first frame.
ImageProvider<Object> imageRamProvider(
  String cacheKey,
  int? w,
  int? h, {
  BaseCacheManager? cacheManager,
}) => ResizeImage.resizeIfNeeded(
  w,
  h,
  CachedNetworkImageProvider(
    cacheKey,
    cacheKey: cacheKey,
    cacheManager: cacheManager,
  ),
);

/// The ImageCache key of [imageRamProvider]. Both providers answer `obtainKey`
/// with a `SynchronousFuture`, so the key is read inline.
Object imageRamKey(String cacheKey, int? w, int? h) {
  Object out = cacheKey; // the SynchronousFuture overwrites this inline
  imageRamProvider(
    cacheKey,
    w,
    h,
  ).obtainKey(ImageConfiguration.empty).then((Object k) => out = k);
  return out;
}

// One RAM key per ImageVariant instance, built on first use. The variants are
// memoised (the widget's resolved-variant memo, the per-asset index), so a
// tile that IS its variant and the load policy's variant scan probe RAM
// without a provider, a ResizeImage and a key per probe. Weak on the variant.
final Expando<Object> _variantRamKeys = Expando<Object>('variantRamKey');

/// [imageRamKey] of [v] at its own wire size (wire == decode), cached on [v].
Object variantRamKey(ImageVariant v) =>
    _variantRamKeys[v] ??= imageRamKey(v.cacheKey, v.wireW, v.wireH);

/// [imageRamKey] of a tile loading [cacheKey] at [w] x [h]: [variant]'s cached
/// key when the tile is exactly that variant (the common case), else built.
/// A caller-supplied cacheKey, the raw-URL fallback of an EXIF-broken asset
/// or a disabled memory cache is not the variant and takes the slow path.
Object tileRamKey(String cacheKey, int? w, int? h, ImageVariant? variant) =>
    (variant != null &&
        w == variant.wireW &&
        h == variant.wireH &&
        cacheKey == variant.cacheKey)
    ? variantRamKey(variant)
    : imageRamKey(cacheKey, w, h);

/// Pending / keepAlive / live status of [imageRamKey].
ImageCacheStatus imageRamStatus(String cacheKey, int? w, int? h) =>
    PaintingBinding.instance.imageCache.statusForKey(
      imageRamKey(cacheKey, w, h),
    );

/// Complete in RAM: a new listener gets the frame synchronously (keepAlive or
/// live, and no longer pending). `ImageCache.containsKey` would miss a
/// live-only entry (on screen, already out of the LRU).
bool imageRamLanded(ImageCacheStatus s) =>
    !s.pending && (s.keepAlive || s.live);

/// [imageRamLanded] for an ImageCache [key] already in hand.
bool imageRamKeyLanded(Object key) =>
    imageRamLanded(PaintingBinding.instance.imageCache.statusForKey(key));
