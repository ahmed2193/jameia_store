import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// CDN responsive-URL transform.
//
// For supported hosts (currently media.jm3eia.com — jameia_mart's CDN) the
// server understands:
//   w      max width in px       e.g. 400
//   h      max height in px      e.g. 200
//   fit    cover | contain | fill | inside | outside   (default: cover)
//   format webp | png | avif                           (default: webp)
//
// We append these per render-site based on the widget's logical size and
// device pixel ratio so the server delivers a bitmap roughly matching the
// painted area — typically a 5–20x bandwidth saving over fetching originals.
// ---------------------------------------------------------------------------
class JameiaCdnTransform {
  JameiaCdnTransform._();

  static const Set<String> _supportedHosts = <String>{'media.jm3eia.com'};

  // WebP everywhere: supports alpha (so transparent category icons, store
  // logos, and product cutouts render correctly) and is the smallest of the
  // formats the CDN offers — hence the `format = 'webp'` default below.

  // Negative-result fast path. A CDN URL string always contains `://host` for
  // a supported host — pre-build the fragment list so the hot path is a cheap
  // "does the URL string contain this substring?" instead of allocating a Uri
  // for every (mostly non-CDN) tile on a scroll.
  static final List<String> _supportedHostFragments = _supportedHosts
      .map((h) => '://$h')
      .toList(growable: false);

  // Small string-keyed memo of resolved URLs. Hit rate on a scrolling grid is
  // very high — the same N visible products produce the same transformed URL
  // every rebuild. Capped at _kMemoMax; cleared whole-cloth on overflow since
  // LRU bookkeeping costs more than the recompute it would save.
  static final Map<String, String> _memo = <String, String>{};
  static const int _kMemoMax = 1024;

  /// Returns [url] with responsive query params appended for supported hosts.
  /// Returns the input unchanged when: URL is empty, parses invalid, points at
  /// an unsupported host, or both [width] and [height] are null.
  static String apply({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    required double dpr,
    String format = 'webp',
  }) {
    if (url.isEmpty) return url;
    // The CDN returns HTTP 500 for double-slash paths (`host//2022/...`):
    // collapse accidental duplicate slashes to the canonical URL the CDN
    // serves 200 + caches (done before the memo + early returns so EVERY
    // resolved URL is clean).
    url = _normalizeSlashes(url);
    if (width == null && height == null) return url;

    // Fast reject: skip Uri.parse for the common case where the URL obviously
    // isn't on a supported CDN host.
    bool maybeSupported = false;
    for (final f in _supportedHostFragments) {
      if (url.contains(f)) {
        maybeSupported = true;
        break;
      }
    }
    if (!maybeSupported) return url;

    final w = (width != null && width.isFinite && width > 0)
        ? _scale(width, dpr)
        : 0;
    final h = (height != null && height.isFinite && height > 0)
        ? _scale(height, dpr)
        : 0;
    final fitParam = _fitToParam(fit);

    // Memo key encodes every input that affects the output.
    final memoKey = '$url|$w|$h|$fitParam|$format';
    final cached = _memo[memoKey];
    if (cached != null) return cached;

    final Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }
    if (!_supportedHosts.contains(uri.host)) return url;

    final params = Map<String, String>.from(uri.queryParameters);
    if (w > 0) params['w'] = w.toString();
    if (h > 0) params['h'] = h.toString();
    params['fit'] = fitParam;
    params['format'] = format;

    final result = uri.replace(queryParameters: params).toString();

    if (_memo.length >= _kMemoMax) _memo.clear();
    _memo[memoKey] = result;
    return result;
  }

  // Static so the pattern is compiled ONCE, not per call — _normalizeSlashes
  // runs on every network build (twice: resolved + raw) before the memo.
  static final RegExp _multiSlash = RegExp(r'/{2,}');

  // Collapse duplicate slashes in the host+path while preserving the scheme
  // and query string: `https://host//a//b?x=1` → `https://host/a/b?x=1`.
  static String _normalizeSlashes(String url) {
    final schemeEnd = url.indexOf('://');
    if (schemeEnd < 0) return url;
    final start = schemeEnd + 3;
    final queryStart = url.indexOf('?', start);
    final end = queryStart < 0 ? url.length : queryStart;
    // Fast path: most URLs are already clean — a cheap indexOf scan returns the
    // input verbatim with ZERO allocation, paying the collapse cost only for
    // the rare malformed `//` URL.
    final dbl = url.indexOf('//', start);
    if (dbl < 0 || dbl >= end) return url;
    final hostPath = url.substring(start, end).replaceAll(_multiSlash, '/');
    return url.substring(0, start) +
        hostPath +
        (queryStart < 0 ? '' : url.substring(queryStart));
  }

  // DPR clamped to 2.0 — above it the on-device sharpness gain is imperceptible
  // while bytes and decode time nearly double. Min 64 avoids absurd thumbnails;
  // max 2048 caps full-screen requests.
  static int _scale(double logicalPx, double dpr) {
    final cap = dpr.clamp(1.0, 2.0);
    return (logicalPx * cap).round().clamp(64, 2048);
  }

  static String _fitToParam(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
      case BoxFit.scaleDown:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
        return 'inside';
      case BoxFit.none:
        return 'cover';
    }
  }
}
