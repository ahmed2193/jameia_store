import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'keeta_image_cache_manager.dart';

// ---------------------------------------------------------------------------
// There is intentionally NO failed-URL blacklist. The rule is "retry forever,
// never show the broken-image icon for anything that might self-heal" — so no
// per-URL fail stamp drives any decision. The only path that ever shows the
// error tile is the empty-url / asset-not-found case; network failures stay on
// the placeholder and are handled by _RetryingNetworkImage's unbounded backoff.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// CDN responsive-URL transform.
//
// For supported hosts (currently media.jm3eia.com — keeta_clone's CDN) the
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
class _CdnTransform {
  static const Set<String> _supportedHosts = <String>{
    'media.jm3eia.com',
  };

  // WebP everywhere: supports alpha (so transparent category icons, store
  // logos, and product cutouts render correctly) and is the smallest of the
  // formats the CDN offers — hence the `format = 'webp'` default below.

  // Negative-result fast path. A CDN URL string always contains `://host` for
  // a supported host — pre-build the fragment list so the hot path is a cheap
  // "does the URL string contain this substring?" instead of allocating a Uri
  // for every (mostly non-CDN) tile on a scroll.
  static final List<String> _supportedHostFragments =
      _supportedHosts.map((h) => '://$h').toList(growable: false);

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

/// Sized, cached network image with skeleton placeholder + graceful error tile.
/// The single image entry point for feature code (never raw `Image.network`).
///
/// Internally: applies a responsive CDN transform (`media.jm3eia.com`), sizes
/// the in-RAM decode to the painted box × DPR, and retries network failures
/// forever on an exponential backoff while keeping the placeholder visible —
/// the broken-image icon is never shown for a remote URL while mounted.
class KeetaImage extends StatelessWidget {
  const KeetaImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.isCircular = false,
  });

  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  /// Explicit in-RAM decode width override. `null` → auto from box × DPR.
  final int? memCacheWidth;

  /// Explicit in-RAM decode height override. `null` → auto from box × DPR.
  final int? memCacheHeight;

  /// Circular clip (used by [circle]). Drives the circular placeholder/error.
  final bool isCircular;

  /// Debug-only dedup set of `(decodeWxH, url)` keys already logged, so a
  /// scroll doesn't flood the log. Capped to stay bounded over long sessions.
  static final Set<String> _debugLoggedKeys = <String>{};
  static const int _kMaxDebugLogKeys = 5000;

  /// Collapses every pending soft-failure retry timer into an immediate retry.
  /// Wire into the reconnect / app-resume path so the moment the network
  /// returns, every grey tile re-attempts at once instead of waiting out its
  /// individual backoff (up to 30 min on the slow tier).
  static void retryAllPendingImages() {
    _RetryingNetworkImageState.retryAllNow();
  }

  static bool _hasUsableDim(double? d) => d != null && d.isFinite && d > 0;

  // Fits whose painted bitmap is guaranteed to stay inside its box, so an outer
  // clip is redundant. fitWidth/fitHeight/none can spill and still need a clip.
  static bool _fitConfined(BoxFit f) =>
      f == BoxFit.cover ||
      f == BoxFit.contain ||
      f == BoxFit.fill ||
      f == BoxFit.scaleDown;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    Widget content;
    if (url.isEmpty) {
      content = _buildEmpty();
    } else if (!_hasUsableDim(width) && !_hasUsableDim(height)) {
      // No usable explicit size — discover the painted area via LayoutBuilder so
      // the CDN transform + decode sizing still fire for layout-driven tiles
      // (Expanded, AspectRatio, …) instead of fetching the original.
      content = LayoutBuilder(
        builder: (ctx, constraints) {
          final layoutW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : null;
          final layoutH =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : null;
          return _buildNetwork(ctx, dpr, layoutWidth: layoutW, layoutHeight: layoutH);
        },
      );
    } else {
      content = _buildNetwork(context, dpr);
    }

    final image = SizedBox(width: width, height: height, child: content);

    // Clip ONLY when needed: rounded corners (ClipRRect) or an overflow-prone
    // fit (cheaper ClipRect). The common sharp-cornered cover/contain tile skips
    // the clip entirely. isCircular is handled by the [circle] ClipOval wrapper.
    final Widget clipped;
    if (radius > 0) {
      clipped = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image,
      );
    } else if (!isCircular && !_fitConfined(fit)) {
      clipped = ClipRect(child: image);
    } else {
      clipped = image;
    }

    // Isolate image repaints from the surrounding list tile.
    return RepaintBoundary(child: clipped);
  }

  Widget _buildNetwork(
    BuildContext context,
    double dpr, {
    double? layoutWidth,
    double? layoutHeight,
  }) {
    // Effective dims: prefer explicit constructor args, fall back to the dims
    // LayoutBuilder discovered. Either way _CdnTransform and _cacheSize see the
    // same numbers so on-wire size and in-RAM decode size agree.
    final effW = _hasUsableDim(width) ? width : layoutWidth;
    final effH = _hasUsableDim(height) ? height : layoutHeight;

    const format = 'webp';
    final resolvedUrl = _CdnTransform.apply(
      url: url,
      width: effW,
      height: effH,
      fit: fit,
      dpr: dpr,
      format: format,
    );
    // Raw fallback: slash-normalised URL with NO transform params. When the
    // transform changed the URL we keep this ready so _RetryingNetworkImage can
    // switch to it on the first failure — some media.jm3eia.com assets carry a
    // malformed EXIF profile whose transform endpoint 500s while the raw file
    // serves 200, self-healing those tiles app-wide.
    final rawUrl = _CdnTransform.apply(
      url: url,
      width: null,
      height: null,
      fit: fit,
      dpr: dpr,
      format: format,
    );
    final String? fallbackUrl = (rawUrl != resolvedUrl) ? rawUrl : null;

    final cw = memCacheWidth ?? _cacheSize(effW, dpr);
    final ch = memCacheHeight ?? _cacheSize(effH, dpr);

    if (kDebugMode) {
      if (_debugLoggedKeys.length >= _kMaxDebugLogKeys) _debugLoggedKeys.clear();
      final logKey = '${cw ?? "src"}x${ch ?? "src"}|$resolvedUrl';
      if (_debugLoggedKeys.add(logKey)) {
        final logicalW =
            effW != null && effW.isFinite ? effW.toStringAsFixed(0) : '?';
        final logicalH =
            effH != null && effH.isFinite ? effH.toStringAsFixed(0) : '?';
        debugPrint(
          '[KeetaImage] '
          'logical=${logicalW}x$logicalH '
          'mem=${cw ?? "src"}x${ch ?? "src"} '
          'dpr=${dpr.toStringAsFixed(1)} '
          'fit=${fit.name} '
          'url=$resolvedUrl',
        );
      }
    }

    return _RetryingNetworkImage(
      // Key on the resolved URL so a parent that swaps the URL out (variant
      // toggle, banner rotation) gets a fresh retry state; pure rebuilds with
      // the same URL preserve the in-flight retry timer.
      key: ValueKey('cni:$resolvedUrl'),
      imageUrl: resolvedUrl,
      fallbackUrl: fallbackUrl,
      cacheKey: resolvedUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cw,
      memCacheHeight: ch,
      placeholderBuilder: (_) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() => const ColoredBox(color: AppColors.smallBackground);

  Widget _buildEmpty() => Container(
        color: AppColors.smallBackground,
        width: width,
        height: height,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: AppColors.disabledText,
          size: 28,
        ),
      );

  // null when size is null/<=0/non-finite, else size × DPR clamped to [50,900].
  int? _cacheSize(double? size, double dpr) {
    if (size == null || size <= 0 || size.isInfinite || size.isNaN) return null;
    final effectiveDpr = dpr.clamp(1.0, 2.0);
    return (size * effectiveDpr).round().clamp(50, 900);
  }

  /// Circular avatar variant.
  static Widget circle({required String url, required double size}) => ClipOval(
        child: KeetaImage(
          url: url,
          width: size,
          height: size,
          isCircular: true,
        ),
      );
}

/// Rounded-card image used in product/shop cards.
class KeetaCardImage extends StatelessWidget {
  const KeetaCardImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppRadius.card,
  });

  final String url;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      KeetaImage(url: url, width: width, height: height, radius: radius);
}

// ---------------------------------------------------------------------------
// _RetryingNetworkImage
//
// Wraps `CachedNetworkImage` with an UNCONDITIONAL auto-retry loop. Every
// failure — timeout, 5xx, 4xx, DNS, socket reset, anything — schedules a retry
// on an exponential backoff and KEEPS THE PLACEHOLDER VISIBLE. The user-facing
// broken-image tile is never reached for a network image while mounted.
//
//   • Backoff: 0.5s,1,2,4,8,15,30,60s,5m,15m,30m then clamped at 30m forever.
//   • Re-attempt: bump an internal counter and rebuild CachedNetworkImage with
//     a new ValueKey so the package re-resolves memory→disk→network. The disk
//     cacheKey is stable so a successful retry repopulates the same slot.
//   • Connectivity hook: every state with a pending timer is registered in
//     _pending. On reconnect, retryAllNow() collapses every backoff into an
//     immediate retry (see KeetaImage.retryAllPendingImages).
// ---------------------------------------------------------------------------
class _RetryingNetworkImage extends StatefulWidget {
  const _RetryingNetworkImage({
    super.key,
    required this.imageUrl,
    this.fallbackUrl,
    required this.cacheKey,
    required this.fit,
    required this.width,
    required this.height,
    required this.memCacheWidth,
    required this.memCacheHeight,
    required this.placeholderBuilder,
  });

  final String imageUrl;
  final String? fallbackUrl;
  final String cacheKey;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget Function(BuildContext context) placeholderBuilder;

  @override
  State<_RetryingNetworkImage> createState() => _RetryingNetworkImageState();
}

class _RetryingNetworkImageState extends State<_RetryingNetworkImage> {
  // Backoff schedule in milliseconds. First retry fires in 500 ms — half a
  // second feels instant to someone staring at a grey tile. Steps double until
  // 60 s, then escalate slowly so a server-side fix becomes visible within
  // half an hour without burning the battery on a hours-dead tile.
  //   500 ms, 1 s, 2 s, 4 s, 8 s, 15 s, 30 s, 60 s, 5 m, 15 m, 30 m
  static const List<int> _backoffMs = <int>[
    500,
    1000,
    2000,
    4000,
    8000,
    15000,
    30000,
    60000,
    5 * 60 * 1000,
    15 * 60 * 1000,
    30 * 60 * 1000,
  ];

  // Jitter ±25%. Without it, N simultaneously-failed tiles retry in lock-step
  // and recreate the failure pattern (TLS-handshake storm, CDN thundering
  // herd). The jitter spreads retries over a window.
  static const double _jitterFraction = 0.25;
  static final math.Random _rng = math.Random();

  // Global concurrency gate — at most this many in-flight image RETRIES at
  // once. 6 matches Chrome's per-host HTTP/1.1 budget: high enough to feel
  // responsive after reconnect, low enough to avoid N parallel TLS handshakes
  // on a saturated link. When exhausted, retries queue in _waiters.
  static const int _maxConcurrent = 6;
  static int _inFlight = 0;
  static final List<_RetryingNetworkImageState> _waiters =
      <_RetryingNetworkImageState>[];

  int _attempt = 0;
  // Once the primary (transformed) URL fails, switch to the raw fallback for
  // every subsequent attempt — handles EXIF-broken CDN assets (transform 500s,
  // raw 200s). Sticky for this widget's life; the raw bytes then cache under
  // the same cacheKey so later mounts hit the cache on attempt 0.
  bool _onFallback = false;
  String get _activeUrl => (_onFallback && widget.fallbackUrl != null)
      ? widget.fallbackUrl!
      : widget.imageUrl;
  Timer? _retryTimer;
  bool _queuedForSlot = false;
  // True between _startAttempt() and the resolving image/error — so dispose()
  // can release a slot if the widget is destroyed mid-flight; without it,
  // fast-scrolling lists eventually exhaust the concurrency budget.
  bool _holdsSlot = false;
  // CachedNetworkImage exposes no success callback; we assume "still alive
  // after 3 s == loaded" and free the slot. Cancelled on failure/dispose.
  Timer? _slotReleaseTimer;

  // Global registry of states with a pending timer OR queued for a slot.
  static final Set<_RetryingNetworkImageState> _pending =
      <_RetryingNetworkImageState>{};

  static void retryAllNow() {
    // Union _pending with _waiters: a tile capped at the concurrency gate parks
    // in _waiters and leaves _pending, so a _pending-only sweep would miss it.
    // Re-running _retryNow on a still-capped waiter simply re-queues it.
    final snapshot = <_RetryingNetworkImageState>{..._pending, ..._waiters};
    for (final s in snapshot) {
      s._retryNow();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _slotReleaseTimer?.cancel();
    _slotReleaseTimer = null;
    _pending.remove(this);
    if (_queuedForSlot) {
      _waiters.remove(this);
      _queuedForSlot = false;
    }
    // Hand the slot back if destroyed mid-fetch — otherwise _inFlight leaks +1
    // per disposed-in-flight tile and a scroll-heavy session starves retries.
    if (_holdsSlot) {
      _holdsSlot = false;
      _releaseSlot();
    }
    super.dispose();
  }

  /// Next backoff delay including ±25% jitter.
  Duration _nextDelay() {
    final idx = _attempt.clamp(0, _backoffMs.length - 1);
    final base = _backoffMs[idx];
    final jitter = (base * _jitterFraction).toInt();
    final spread = jitter == 0 ? 0 : _rng.nextInt(jitter * 2) - jitter;
    return Duration(milliseconds: (base + spread).clamp(100, 60 * 60 * 1000));
  }

  void _scheduleRetry() {
    if (!mounted) return;
    _retryTimer?.cancel();
    _pending.add(this);
    _retryTimer = Timer(_nextDelay(), _retryNow);
  }

  void _retryNow() {
    _retryTimer?.cancel();
    _pending.remove(this);
    // A Timer callback can fire on the same micro-tick as dispose() — re-check
    // mounted before any state mutation.
    if (!mounted || !context.mounted) return;
    if (_inFlight >= _maxConcurrent) {
      if (!_queuedForSlot) {
        _waiters.add(this);
        _queuedForSlot = true;
      }
      return;
    }
    _startAttempt();
  }

  void _startAttempt() {
    if (!mounted) return;
    _inFlight++;
    _holdsSlot = true;
    _armSlotRelease();
    if (kDebugMode) {
      debugPrint(
        '[KeetaImage:retry] attempt=${_attempt + 1} '
        'inFlight=$_inFlight/$_maxConcurrent '
        '${_onFallback ? "(raw) " : ""}url=$_activeUrl',
      );
    }
    // Await the disk evict so the rebuild can't race the delete; disk I/O is
    // ~5-20 ms, negligible against the user-facing backoff already elapsed.
    KeetaImageCacheManager.removeFile(widget.cacheKey).then((_) {
      if (!mounted) {
        if (_holdsSlot) _releaseSlot();
        return;
      }
      setState(() => _attempt++);
    }).catchError((_) {
      if (!mounted) {
        if (_holdsSlot) _releaseSlot();
        return;
      }
      setState(() => _attempt++);
    });
  }

  void _releaseSlot() {
    _holdsSlot = false;
    _inFlight = (_inFlight - 1).clamp(0, _maxConcurrent);
    while (_inFlight < _maxConcurrent && _waiters.isNotEmpty) {
      final next = _waiters.removeAt(0);
      next._queuedForSlot = false;
      if (next.mounted) next._startAttempt();
    }
  }

  // Deferred slot-release for the in-flight attempt. No success callback exists,
  // so "still alive after 3 s == loaded" frees the slot for a queued waiter.
  void _armSlotRelease() {
    _slotReleaseTimer?.cancel();
    _slotReleaseTimer = Timer(const Duration(seconds: 3), () {
      _slotReleaseTimer = null;
      if (!mounted) return;
      if (_holdsSlot) _releaseSlot();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      // Bumping the key on every retry forces the package to discard its
      // previous failed ImageStream and re-resolve memory→disk→network.
      key: ValueKey('${widget.cacheKey}#$_attempt${_onFallback ? 'r' : ''}'),
      cacheKey: widget.cacheKey,
      imageUrl: _activeUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      fadeInDuration: AppMotion.imageFade,
      cacheManager: KeetaImageCacheManager.instance,
      // gaplessPlayback in cached_network_image is derived from this flag — it
      // keeps the previous frame on screen during a re-resolve (no flash).
      useOldImageOnUrlChange: true,
      // Low filter quality is correct when the bitmap is already sized to the
      // viewport via memCacheW/H — medium adds GPU cost with no visible gain.
      filterQuality: FilterQuality.low,
      placeholder: (ctx, _) => widget.placeholderBuilder(ctx),
      errorWidget: (ctx, failedUrl, error) {
        // EVERY failure → schedule a retry. No classification, no give-up. The
        // placeholder stays visible while we wait, so the user never sees the
        // broken-image icon for a transient (or permanent) network issue while
        // this widget is mounted.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _slotReleaseTimer?.cancel();
          _slotReleaseTimer = null;
          if (_holdsSlot) _releaseSlot();
          // First failure of the primary URL → switch to the raw fallback and
          // retry immediately so EXIF-broken tiles recover in one hop instead
          // of looping on the 500. Otherwise normal backoff.
          if (!_onFallback && widget.fallbackUrl != null) {
            _onFallback = true;
            _retryNow();
          } else {
            _scheduleRetry();
          }
        });
        return widget.placeholderBuilder(ctx);
      },
    );
  }
}
