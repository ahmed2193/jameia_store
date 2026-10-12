import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart' show BoxFit;

import 'image_key_policy.dart';
import 'image_variant_index.dart';

/// The per-process state on top of the image key policy
/// (image_key_policy.dart): the resolved-variant memo and the
/// transform-broken registry. Ported from the reference app's
/// `_CdnTransform` (jm3eia_mobile `app_image.dart`).
///
/// The CDN (`media.jm3eia.com`) understands `w` / `h` (px), `fit`
/// (`cover | contain | fill | inside`) and `format`; every URL on it leaves
/// with at least `fit` + `format=webp`, even with no size, so nothing is ever
/// served as its source JPEG / PNG. The resolved URL is the disk cacheKey and
/// the wire size is the RAM decode size.
abstract final class ImageCdnTransform {
  /// WebP everywhere: alpha (transparent cut-outs, logos), the smallest of
  /// the CDN's formats, decoded natively on Android and iOS.
  static const String format = 'webp';

  // Assets whose TRANSFORM endpoint is known-broken for this process. A
  // handful of CDN files carry a malformed embedded EXIF profile: any
  // reprocessing param makes the CDN answer 4xx/5xx while the raw file serves
  // 200. The first tile that hits it registers the asset here, so every other
  // render site of the same image skips the doomed transform. Keyed by the
  // asset id (canonical URL without its query): all sizes and spellings of
  // one asset share the verdict. Process lifetime: a server fix is picked up
  // on the next launch.
  static final Set<String> _transformBroken = <String>{};
  static const int _brokenMax = 512;

  // Resolved variants, two levels deep: the canonical URL (the memoised
  // string from canonicalImageUrl, whose hash is cached), then an int slot
  // packing the wire size and the fit (see [variant]). A hit allocates
  // nothing and hands back the SAME instance. Cleared whole-cloth on
  // overflow: LRU bookkeeping costs more than a recompute.
  static final Map<String, Map<int, ImageVariant>> _memo =
      <String, Map<int, ImageVariant>>{};
  static int _memoCount = 0;
  static const int _memoMax = 1024;

  // wireW above bit 20, wireH in bits 6..19, BoxFit.index (0..6) in bits
  // 3..5 (bits 0..2 stay free: one format).
  static const int _slotWLimit = 1 << 20;
  static const int _slotHLimit = 1 << 14;
  static const int _slotWShift = 20;
  static const int _slotHShift = 6;
  static const int _slotFitShift = 3;

  /// Records that [url]'s transform endpoint answered a hard error, so every
  /// render site of the same asset goes straight to the raw file.
  static void markTransformBroken(String url) {
    if (url.isEmpty) return;
    if (_transformBroken.length >= _brokenMax) _transformBroken.clear();
    _transformBroken.add(assetId(canonicalImageUrl(url)));
  }

  /// Whether the asset of [canonical] is known to break the transform.
  static bool isBroken(String canonical) =>
      _transformBroken.isNotEmpty &&
      _transformBroken.contains(assetId(canonical));

  /// The canonical URL with NO transform params: the raw-file fallback. It
  /// stays parameter-free on purpose (even `format=webp` re-triggers the
  /// re-encode that broke).
  static String raw(String url) => canonicalImageUrl(url);

  /// The variant of [canonical] at the (bucketed) wire size, or `null` for a
  /// host that does not transform. A new variant is recorded in
  /// [ImageVariantIndex] (the load policy's cached-variant probe); a memo hit
  /// never reaches the index.
  static ImageVariant? variant({
    required String canonical,
    required int? wireW,
    required int? wireH,
    required BoxFit fit,
  }) {
    if (!isMediaUrl(canonical)) return null;
    // A size outside the packable range (the ladder tops out at 2048, so
    // only a bug gets here) is built directly: correct, just not memoised.
    if ((wireW != null && (wireW <= 0 || wireW >= _slotWLimit)) ||
        (wireH != null && (wireH <= 0 || wireH >= _slotHLimit))) {
      return _create(canonical, wireW, wireH, fit);
    }
    // wireW / wireH are null (axis not sent) or > 0, so 0 stands for null.
    final int slot =
        ((wireW ?? 0) << _slotWShift) |
        ((wireH ?? 0) << _slotHShift) |
        (fit.index << _slotFitShift);
    final ImageVariant? cached = _memo[canonical]?[slot];
    if (cached != null) return cached;
    if (_memoCount >= _memoMax) {
      _memo.clear();
      _memoCount = 0;
    }
    final ImageVariant created = _create(canonical, wireW, wireH, fit);
    (_memo[canonical] ??= <int, ImageVariant>{})[slot] = created;
    _memoCount++;
    return created;
  }

  /// The URL actually fetched for [canonical]: [v]'s transformed URL, or the
  /// raw canonical URL for a host that does not transform or a known
  /// EXIF-broken asset. The broken check runs on every call (not memoised),
  /// so one tile's verdict governs every other render site at once.
  static String resolve(String canonical, ImageVariant? v) =>
      (v == null || isBroken(canonical)) ? canonical : v.resolvedUrl;

  /// Forgets the registry and the memo (tests only).
  @visibleForTesting
  static void debugReset() {
    _transformBroken.clear();
    _memo.clear();
    _memoCount = 0;
  }

  // The one place a new variant is made, and so the one place it is recorded
  // in the per-asset index.
  static ImageVariant _create(
    String canonical,
    int? wireW,
    int? wireH,
    BoxFit fit,
  ) {
    final ImageVariant v = ImageVariant.of(
      canonical,
      wireW: wireW,
      wireH: wireH,
      fit: cdnFitParam(fit),
      format: format,
    );
    ImageVariantIndex.instance.record(v.assetId, v);
    return v;
  }
}
