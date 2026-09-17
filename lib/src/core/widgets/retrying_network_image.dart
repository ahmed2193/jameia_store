import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import 'jameia_image_cache_manager.dart';

// ---------------------------------------------------------------------------
// RetryingNetworkImage
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
//     immediate retry (see JameiaImage.retryAllPendingImages).
// ---------------------------------------------------------------------------
class RetryingNetworkImage extends StatefulWidget {
  const RetryingNetworkImage({
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

  /// Collapses every pending retry timer (and every tile queued behind the
  /// concurrency gate) into an immediate retry.
  static void retryAllNow() => _RetryingNetworkImageState.retryAllNow();

  @override
  State<RetryingNetworkImage> createState() => _RetryingNetworkImageState();
}

class _RetryingNetworkImageState extends State<RetryingNetworkImage> {
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
  static const Duration _slotReleaseDelay = Duration(seconds: 3);

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
      log(
        'attempt=${_attempt + 1} '
        'inFlight=$_inFlight/$_maxConcurrent '
        '${_onFallback ? "(raw) " : ""}url=$_activeUrl',
        name: 'JameiaImage:retry',
      );
    }
    // Await the disk evict so the rebuild can't race the delete; disk I/O is
    // ~5-20 ms, negligible against the user-facing backoff already elapsed.
    JameiaImageCacheManager.removeFile(widget.cacheKey)
        .then((_) {
          if (!mounted) {
            if (_holdsSlot) _releaseSlot();
            return;
          }
          setState(() => _attempt++);
        })
        .catchError((_) {
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
    _slotReleaseTimer = Timer(_slotReleaseDelay, () {
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
      cacheManager: JameiaImageCacheManager.instance,
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
