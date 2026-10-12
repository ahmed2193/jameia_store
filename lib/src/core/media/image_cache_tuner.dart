import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'media_log.dart';
import 'trimming_image_cache.dart';

/// Adaptive image-cache sizer.
///
/// Picks the budget once, at [install], from **MemTotal** (low / mid / high,
/// [tierFor]). No step-down for low MemAvailable at startup: on the reference
/// app's Xiaomi (MIUI) 22 of 44 cold starts read < 25 % available, which put
/// a 3.5 GB phone on the 80 MB tier, whose 40 MB trim target sits below the
/// measured 49–55 MB working set (jm3eia_mobile
/// `docs/audit/image_cache/PHASE5_TUNER_REVIEW.md`). Real shortage is
/// answered by the OS's own pressure signal, which now trims instead of
/// wiping.
///
/// Memory pressure is answered by [TrimmingImageCache] (installed by
/// `HeroWidgetsBinding`): the framework's `imageCache.clear()` becomes a
/// rate-limited LRU trim to half the budget, taken only if the app is still
/// in front a moment later. The tuner never shrinks or tiers down on
/// pressure: MIUI fired 638 pressure callbacks in ~110 min, in bursts of 3–4
/// within 5 ms, so a "repeat within 90 s → permanent tier-down" rule pinned
/// the budget at 40 MB for whole sessions (`DIAGNOSIS.md` H5/H8). The
/// observer below only logs (debug). Backgrounding keeps the cache.
class ImageCacheTuner {
  ImageCacheTuner._();

  static bool _installed = false;
  static _CacheTier _activeTier = _CacheTier.mid;

  static Future<void> install() async {
    if (_installed) return;
    _installed = true;

    _activeTier = _tierFor(await _readMemTotalGb());
    final ImageCache cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = _activeTier.bytes;
    cache.maximumSize = _activeTier.count;

    _debugLog(
      'tier=${_activeTier.name} maxBytes=${_mb(_activeTier.bytes, 0)}MB '
      'maxCount=${_activeTier.count}',
    );
    WidgetsBinding.instance.addObserver(_MemoryPressureObserver());
  }

  /// The tier table: (name, maxBytes, maxCount) for a device with [totalGb]
  /// of MemTotal; unknown (≤ 0, every non-Android host) is mid.
  @visibleForTesting
  static ({String name, int bytes, int count}) tierFor(double totalGb) {
    final _CacheTier t = _tierFor(totalGb);
    return (name: t.name, bytes: t.bytes, count: t.count);
  }

  static _CacheTier _tierFor(double totalGb) {
    if (totalGb <= 0) return _CacheTier.mid;
    if (totalGb <= 2) return _CacheTier.low;
    if (totalGb <= 4) return _CacheTier.mid;
    return _CacheTier.high;
  }

  static Future<double> _readMemTotalGb() async {
    try {
      if (Platform.isAndroid) {
        final File f = File('/proc/meminfo');
        if (await f.exists()) {
          for (final String l in await f.readAsLines()) {
            if (l.startsWith('MemTotal:')) return _parseLineGb(l);
          }
        }
      }
    } on PlatformException catch (_) {
    } catch (_) {}
    return -1;
  }

  static double _parseLineGb(String line) {
    final RegExpMatch? m = RegExp(r'(\d+)').firstMatch(line);
    if (m == null) return -1;
    return int.parse(m.group(1)!) / 1024 / 1024;
  }

  // Debug log only. PaintingBinding handles pressure BEFORE WidgetsBinding
  // notifies observers, so by now the framework's `imageCache.clear()` has
  // already run — as a TrimmingImageCache signal. The budget is left alone:
  // the trim is the single pressure response. NEVER call clearAll() or
  // clearLiveImages() here.
  static void _onMemoryPressure() =>
      _debugLog('memory pressure: ${_cacheSummary()}');

  // Intentionally NO clear on `detached` (some Android flows fire it with the
  // engine alive) and NO trim on `hidden` / `paused` (frames are already off,
  // so evicted bitmaps would not be released before resume).
  static void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.resumed) {
      _debugLog('${state.name}: ${_cacheSummary()}');
    }
  }

  static String _cacheSummary() {
    final ImageCache c = PaintingBinding.instance.imageCache;
    final String trims = c is TrimmingImageCache ? ' trims=${c.trimCount}' : '';
    return 'cache ${c.currentSize}/${c.maximumSize} entries / '
        '${_mb(c.currentSizeBytes)}/${_mb(c.maximumSizeBytes)} MB '
        'live=${c.liveImageCount} tier=${_activeTier.name}$trims';
  }

  static void _debugLog(String message) {
    if (kDebugMode) MediaLog.line(MediaLog.tuner, message);
  }

  static String _mb(int bytes, [int digits = 1]) =>
      (bytes / 1024 / 1024).toStringAsFixed(digits);
}

// Reviewed by the reference app against its measured working set (282–315
// entries / 49–55 MB, zero evictions) and peer defaults: unchanged. Low is the
// ≤ 2 GB tier and must stay what such a device can hold.
class _CacheTier {
  const _CacheTier(this.name, this.bytes, this.count);

  final String name;
  final int bytes;
  final int count;

  static const _CacheTier low = _CacheTier('low', 80 << 20, 800);
  static const _CacheTier mid = _CacheTier('mid', 160 << 20, 1500);
  static const _CacheTier high = _CacheTier('high', 256 << 20, 2400);
}

class _MemoryPressureObserver with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() => ImageCacheTuner._onMemoryPressure();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      ImageCacheTuner._onLifecycle(state);
}
