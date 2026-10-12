import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import 'hero_image_cache_manager.dart';
import 'image_cdn_transform.dart';
import 'image_disk_index.dart';
import 'image_load_failure.dart';
import 'image_load_trace.dart';
import 'image_request.dart';
import 'media_log.dart';

/// The image tile a retry machine drives (its `State`).
abstract interface class ImageRetryHost {
  /// Still mounted: a timer can fire on the same tick as dispose.
  bool get alive;

  /// The disk cacheKey evicted before every attempt.
  String get retryKey;

  /// The URL the next attempt fetches (the debug line).
  String get activeUrl;

  /// Runs [step] (the attempt bump) inside `setState`.
  void retryStep(void Function() step);
}

/// One image tile's UNCONDITIONAL retry loop, ported from the reference's
/// `_RetryingNetworkImageState` (jm3eia_mobile `app_image.dart`). Every
/// failure — timeout, 4xx / 5xx, DNS, socket reset — retries on a jittered
/// backoff while the tile keeps its placeholder: the broken-image icon is
/// never shown for a URL that might still heal.
///
/// * Backoff ([backoff]): 0.5 s, 1, 2, 4, 8, 15, 30, 60 s, 5, 15, 30 min,
///   then 30 min forever, ±25 % jitter so tiles that failed together do not
///   retry in lock-step (a TLS / CDN thundering herd).
/// * At most [maxConcurrent] retries in flight app-wide (Chrome's per-host
///   HTTP/1.1 budget); the rest queue for a slot. First loads are not gated.
/// * An attempt evicts the disk entry first ([HeroImageCacheManager]
///   .removeFile, awaited) and then bumps [attempt], which the tile folds
///   into its inner `CachedNetworkImage` key: memory → disk → network again.
/// * [retryAllNow] (the app's reconnect hook, `HeroImage.retryAllPendingImages`)
///   collapses every pending backoff — and every tile queued for a slot —
///   into an immediate retry.
class ImageRetryMachine {
  ImageRetryMachine(this._host);

  final ImageRetryHost _host;

  /// The wait before each attempt, by attempt index; the last one repeats.
  static const List<Duration> backoff = <Duration>[
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  /// ± this share of each backoff step.
  static const double jitterFraction = 0.25;

  /// Retries in flight at once, app-wide.
  static const int maxConcurrent = 6;

  /// No success callback exists, so an attempt still alive this long is
  /// taken as loaded and its slot goes to a waiter (a slower download keeps
  /// going; its eventual failure takes a fresh slot).
  static const Duration slotRelease = Duration(seconds: 3);

  static const int _minDelayMs = 100;
  static const int _maxDelayMs = 60 * 60 * 1000;

  static final math.Random _rng = math.Random();
  static int _inFlight = 0;
  static final List<ImageRetryMachine> _waiters = <ImageRetryMachine>[];
  // Machines with a backoff timer pending (see [retryAllNow]).
  static final Set<ImageRetryMachine> _pending = <ImageRetryMachine>{};

  int _attempt = 0;
  bool _onFallback = false;
  Timer? _retryTimer;
  bool _queuedForSlot = false;
  // Between [_startAttempt] and the failure / [slotRelease] / dispose that
  // hands the slot back; without it a disposed in-flight tile would leak one.
  bool _holdsSlot = false;
  Timer? _slotReleaseTimer;
  // Bumped by [reset]: an eviction awaited for the OLD cacheKey must not
  // start an attempt on the new one.
  int _gen = 0;

  /// Attempts made so far (0 = the first load).
  int get attempt => _attempt;

  /// Sticky once the primary URL failed (not by a stalled body): every later
  /// attempt fetches the raw fallback, under the same cacheKey.
  bool get onFallback => _onFallback;

  /// Retries in flight app-wide (tests only).
  @visibleForTesting
  static int get debugInFlight => _inFlight;

  /// Every pending backoff, and every tile waiting for a slot, retries now.
  /// A still-capped waiter simply queues again.
  static void retryAllNow() {
    final Set<ImageRetryMachine> all = <ImageRetryMachine>{
      ..._pending,
      ..._waiters,
    };
    for (final ImageRetryMachine m in all) {
      m._retryNow();
    }
  }

  /// A load of [request] failed with [error] (octo's error builder, mid-
  /// build), so the rest waits for the end of the frame. The first failure
  /// of a transformed URL hops to the raw file (EXIF-broken transforms)
  /// under the same cacheKey: the disk index is told which key those bytes
  /// land under, and only a server reject marks the asset transform-broken
  /// (a timeout or a socket reset is no verdict on it). A stalled body says
  /// nothing about the URL: like every later failure, it waits out the
  /// backoff on the same URL.
  void loadFailed(Object error, ImageRequest request) {
    final bool serverRejected = ImageLoadFailure.isServerReject(error);
    final bool stalled = ImageLoadFailure.isStalled(error);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_host.alive || _host.retryKey != request.cacheKey) return;
      final String? raw = request.fallbackUrl;
      final bool hop = !stalled && !_onFallback && raw != null;
      if (hop) {
        ImageDiskIndex.instance.expectDownload(raw, request.cacheKey);
        if (serverRejected) {
          ImageCdnTransform.markTransformBroken(request.imageUrl);
        }
      }
      _failed(hopToFallback: hop);
    });
  }

  // The current attempt failed: its slot goes back, then either the raw
  // fallback right away ([hopToFallback]) or the next backoff step.
  void _failed({required bool hopToFallback}) {
    _slotReleaseTimer?.cancel();
    _slotReleaseTimer = null;
    if (_holdsSlot) _releaseSlot();
    if (hopToFallback) {
      _onFallback = true;
      _retryNow();
    } else {
      _scheduleRetry();
    }
  }

  /// A new cacheKey on the same tile: start over as a fresh mount would.
  void reset() {
    _gen++;
    _stop();
    _attempt = 0;
    _onFallback = false;
  }

  void dispose() => _stop();

  // Cancels both timers, leaves the queues and hands a held slot back.
  void _stop() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _slotReleaseTimer?.cancel();
    _slotReleaseTimer = null;
    _pending.remove(this);
    if (_queuedForSlot) {
      _waiters.remove(this);
      _queuedForSlot = false;
    }
    if (_holdsSlot) _releaseSlot();
  }

  Duration _nextDelay() {
    final int base =
        backoff[_attempt.clamp(0, backoff.length - 1)].inMilliseconds;
    final int jitter = (base * jitterFraction).toInt();
    final int spread = jitter == 0 ? 0 : _rng.nextInt(jitter * 2) - jitter;
    return Duration(
      milliseconds: (base + spread).clamp(_minDelayMs, _maxDelayMs),
    );
  }

  void _scheduleRetry() {
    if (!_host.alive) return;
    _retryTimer?.cancel();
    _pending.add(this);
    _retryTimer = Timer(_nextDelay(), _retryNow);
  }

  void _retryNow() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _pending.remove(this);
    if (!_host.alive) return;
    if (_inFlight >= maxConcurrent) {
      if (!_queuedForSlot) {
        _waiters.add(this);
        _queuedForSlot = true;
      }
      return;
    }
    _startAttempt();
  }

  void _startAttempt() {
    if (!_host.alive) return;
    _inFlight++;
    _holdsSlot = true;
    _slotReleaseTimer?.cancel();
    _slotReleaseTimer = Timer(slotRelease, () {
      _slotReleaseTimer = null;
      if (_host.alive && _holdsSlot) _releaseSlot();
    });
    if (kDebugMode && ImageLoadTrace.enabled) {
      MediaLog.line(
        MediaLog.trace,
        'retry attempt=${_attempt + 1} inFlight=$_inFlight/$maxConcurrent '
        '${_onFallback ? '(raw) ' : ''}url=${_host.activeUrl}',
      );
    }
    // The previous attempt may have left a partial file: evict it first,
    // awaited so the rebuild cannot race the delete.
    final int gen = _gen;
    HeroImageCacheManager.removeFile(_host.retryKey)
        .then((_) => _advance(gen), onError: (Object _) => _advance(gen));
  }

  void _advance(int gen) {
    if (!_host.alive) {
      if (_holdsSlot) _releaseSlot();
      return;
    }
    if (gen != _gen) return;
    _host.retryStep(() => _attempt++);
  }

  void _releaseSlot() {
    _holdsSlot = false;
    _inFlight = (_inFlight - 1).clamp(0, maxConcurrent);
    while (_inFlight < maxConcurrent && _waiters.isNotEmpty) {
      final ImageRetryMachine next = _waiters.removeAt(0);
      next._queuedForSlot = false;
      if (next._host.alive) next._startAttempt();
    }
  }
}
