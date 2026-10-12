import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import 'image_load_trace.dart';
import 'media_log.dart';

/// An [ImageCache] whose [clear] TRIMS instead of wiping.
///
/// Why: Android forwards every trim level ≥ RUNNING_LOW (including
/// `TRIM_MEMORY_UI_HIDDEN` on each backgrounding) as a memory-pressure
/// message, and `PaintingBinding.handleMemoryPressure` answers it with
/// `imageCache.clear()`. On the reference app's MIUI phone that fired 638×
/// in ~110 min, foreground included, so every off-screen image came back
/// through the disk path with a placeholder (jm3eia_mobile
/// `docs/audit/image_cache/DIAGNOSIS.md`, H8/H5).
///
/// [clear] evicts least-recently-used entries until the cache holds at most
/// [trimFraction] of [maximumSizeBytes] AND of [maximumSize], then restores
/// both limits. Live images (on screen, or with any listener) are never
/// touched. At most one trim per [minInterval] (bursts of 3–4 callbacks
/// within 5 ms were observed), and only if the app is still in front
/// [settleDelay] later. [clearAll] is the original wipe.
class TrimmingImageCache extends ImageCache {
  TrimmingImageCache({
    this.trimFraction = 0.5,
    this.minInterval = const Duration(seconds: 30),
    this.settleDelay = const Duration(milliseconds: 400),
  }) : assert(trimFraction > 0 && trimFraction < 1);

  /// Share of each limit the cache may keep after a trim.
  final double trimFraction;

  /// Minimum time between two trims; calls inside it do nothing.
  final Duration minInterval;

  /// How long a signal that arrives with the app in front waits before it
  /// trims (see [clear]).
  final Duration settleDelay;

  Timer? _settle;

  /// Whether a signal is waiting out [settleDelay].
  bool get trimPending => _settle != null;

  /// Clock used by the rate limit; tests replace it.
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  /// When the last trim ran, or null before the first one.
  DateTime? lastTrimAt;

  /// How many trims have run (rate-limited calls are not counted).
  int trimCount = 0;

  /// Sizes around the last trim, for debug logging.
  ({int entriesBefore, int entriesAfter, int bytesBefore, int bytesAfter})?
  lastTrim;

  /// Memory pressure: a rate-limited LRU trim, decided [settleDelay] later. A
  /// limit of 0 (cache disabled, or a caller setting `maximumSize = 0` to
  /// empty it) still wipes at once, as documented on the setters.
  ///
  /// Never trims while the app is away (frames off, or lifecycle hidden /
  /// paused / detached): `SchedulerBinding.handleAppLifecycleStateChanged`
  /// turns frames OFF before the observers hear of it, and an evicted entry's
  /// bitmap is released only in a post-frame callback (`_CachedImageBase.
  /// dispose`), so a trim while away frees nothing and costs the entries on
  /// resume. (Before `runApp` attaches a root widget, frames are off too.)
  ///
  /// With the app in front the decision waits [settleDelay]: a HOME press can
  /// deliver its own UI_HIDDEN signal BEFORE the `hidden` lifecycle message,
  /// with frames still on. The app binding forwards each lifecycle change to
  /// [handleLifecycle], which drops the pending trim; the window's end
  /// re-checks too. A further signal restarts the window. Neither a deferred
  /// nor a pending signal touches [lastTrimAt].
  @override
  void clear() {
    if (maximumSizeBytes == 0 || maximumSize == 0) {
      _cancelSettle();
      return super.clear();
    }
    if (!_appInFront) {
      _cancelSettle();
      _debugLog('trim deferred (frames off)');
      return;
    }
    // Nothing to trim, or trimmed lately: no window, and an empty cache does
    // not open the rate-limit window either.
    if (currentSize == 0 || _rateLimited(now())) return;
    _settle?.cancel();
    _settle = Timer(settleDelay, _settled);
    _debugLog('pressure → trim pending (${settleDelay.inMilliseconds} ms)');
  }

  /// A lifecycle change (from `HeroWidgetsBinding`): leaving the foreground
  /// drops a trim still waiting out [settleDelay].
  void handleLifecycle(AppLifecycleState state) {
    if (_settle == null || _inFront(state)) return;
    _cancelSettle();
    _debugLog('pending trim dropped (${state.name})');
  }

  /// The framework's full wipe: every cached and pending entry goes. For
  /// callers that mean it (tests, hot-reload asset eviction, debug actions) —
  /// never for memory pressure.
  void clearAll() {
    _cancelSettle();
    super.clear();
  }

  void _settled() {
    _settle = null;
    if (_appInFront) {
      _trim();
    } else {
      _debugLog('pending trim dropped (away)');
    }
  }

  void _trim() {
    final int maxBytes = maximumSizeBytes;
    final int maxCount = maximumSize;
    if (maxBytes == 0 || maxCount == 0 || currentSize == 0) return;
    final DateTime at = now();
    if (_rateLimited(at)) return;

    // Debug trace only (`[IMGCACHE] trim`): what the eviction costs.
    final Stopwatch? watch = kDebugMode && ImageLoadTrace.enabled
        ? (Stopwatch()..start())
        : null;
    final int entriesBefore = currentSize;
    final int bytesBefore = currentSizeBytes;
    // Lowering a limit evicts LRU entries synchronously; never down to 0,
    // which would re-enter clear(). Restoring evicts nothing more.
    maximumSizeBytes = math.max(1, (maxBytes * trimFraction).floor());
    maximumSize = math.max(1, (maxCount * trimFraction).floor());
    maximumSize = maxCount;
    maximumSizeBytes = maxBytes;
    watch?.stop();
    // An evicted bitmap is released in a post-frame callback and an idle
    // foreground screen schedules no frame: ask for one, or the memory stays
    // held until something animates. The app is in front, frames are on.
    if (currentSize < entriesBefore) {
      SchedulerBinding.instance.ensureVisualUpdate();
    }

    lastTrimAt = at;
    trimCount++;
    lastTrim = (
      entriesBefore: entriesBefore,
      entriesAfter: currentSize,
      bytesBefore: bytesBefore,
      bytesAfter: currentSizeBytes,
    );
    _debugLog(
      'pressure → trimmed $entriesBefore→$currentSize entries / '
      '${_mb(bytesBefore)}→${_mb(currentSizeBytes)} MB (#$trimCount, '
      'live=$liveImageCount, cap ${_mb(maxBytes)} MB/$maxCount)',
    );
    if (watch != null) {
      ImageLoadTrace.onTrim(
        entriesBefore: entriesBefore,
        entriesAfter: currentSize,
        bytesBefore: bytesBefore,
        bytesAfter: currentSizeBytes,
        live: liveImageCount,
        took: watch.elapsed,
      );
    }
  }

  bool _rateLimited(DateTime at) {
    final DateTime? last = lastTrimAt;
    if (last == null || at.difference(last) >= minInterval) return false;
    _debugLog(
      'pressure → trim skipped, ${at.difference(last).inMilliseconds} ms '
      'after #$trimCount (window ${minInterval.inSeconds} s)',
    );
    return true;
  }

  void _cancelSettle() {
    _settle?.cancel();
    _settle = null;
  }

  static bool get _appInFront {
    final SchedulerBinding b = SchedulerBinding.instance;
    return b.framesEnabled && _inFront(b.lifecycleState);
  }

  // `inactive` still draws (a system dialog over the app); null = no
  // lifecycle message yet.
  static bool _inFront(AppLifecycleState? s) =>
      s == null ||
      s == AppLifecycleState.resumed ||
      s == AppLifecycleState.inactive;

  static void _debugLog(String message) {
    if (kDebugMode) MediaLog.line(MediaLog.tuner, message);
  }

  static String _mb(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(1);
}
