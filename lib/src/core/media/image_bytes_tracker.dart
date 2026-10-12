import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show FileInfo;

import 'hero_image_cache_manager.dart';
import 'media_log.dart';

/// Debug byte audit: the on-disk size of the network images a screen shows.
///
///   1. A screen calls [beginScope] when it mounts (debug only).
///   2. The image widget registers each resolved URL with [track] while
///      [enabled].
///   3. [endScope] on dispose logs the totals; a debounced snapshot is logged
///      meanwhile.
///
/// Off unless `--dart-define=IMGCACHE_TRACE=true` (which also turns on the
/// `[IMGCACHE]` load trace) or a debug session flips [enabled]. Lines go to
/// the VM log under `ImageBytes`.
class ImageBytesTracker {
  ImageBytesTracker._();

  /// Compile-time constant in release, which keeps the literal `false`.
  static bool enabled =
      kDebugMode && const bool.fromEnvironment('IMGCACHE_TRACE');

  /// Single-image size above which the URL is flagged as an offender.
  static int warnBytes = 200 * 1024;

  /// Total scope size above which the whole screen is flagged as heavy.
  static int warnTotalBytes = 3 * 1024 * 1024;

  static const Duration _logDebounce = Duration(milliseconds: 800);

  static String? _scope;
  static final Set<String> _seen = <String>{};
  static final Map<String, int> _bytesByUrl = <String, int>{};
  static int _pendingFetches = 0;
  static Timer? _logTimer;

  static void beginScope(String name) {
    if (!enabled) return;
    _scope = name;
    _seen.clear();
    _bytesByUrl.clear();
    _pendingFetches = 0;
    _logTimer?.cancel();
    _log('>>> begin scope "$name"');
  }

  static void endScope() {
    if (!enabled || _scope == null) return;
    _logTotals(isFinal: true);
    _scope = null;
    _seen.clear();
    _bytesByUrl.clear();
    _logTimer?.cancel();
    _logTimer = null;
  }

  /// Records [url]'s size on disk. Cache-only: never triggers a download; a
  /// URL not cached yet is skipped and tried again on the next render.
  static void track(String url) {
    if (!enabled || _scope == null || url.isEmpty) return;
    if (!_seen.add(url)) return;
    _pendingFetches++;
    HeroImageCacheManager.instance.getFileFromCache(url).then((
      FileInfo? info,
    ) async {
      try {
        if (info != null) {
          _bytesByUrl[url] = await info.file.length();
        } else {
          _seen.remove(url); // a later hit can still record the size
        }
      } catch (e) {
        _log('size fetch failed for $url: $e');
      } finally {
        _pendingFetches--;
        _scheduleLog();
      }
    });
  }

  static void _scheduleLog() {
    _logTimer?.cancel();
    _logTimer = Timer(_logDebounce, () {
      if (_pendingFetches == 0) _logTotals();
    });
  }

  static void _logTotals({bool isFinal = false}) {
    if (_scope == null) return;
    final int total = _bytesByUrl.values.fold<int>(0, (int a, int b) => a + b);
    final double kb = total / 1024;
    final bool heavy = total > warnTotalBytes;
    final List<MapEntry<String, int>> sorted = _bytesByUrl.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );
    final List<MapEntry<String, int>> offenders = sorted
        .where((MapEntry<String, int> e) => e.value > warnBytes)
        .toList();
    _log(
      '${isFinal ? 'FINAL' : 'snapshot'} scope="$_scope" '
      'images=${_bytesByUrl.length}/${_seen.length} total=${total}B '
      '(${kb.toStringAsFixed(1)} KB / ${(kb / 1024).toStringAsFixed(2)} MB) '
      'pending=$_pendingFetches'
      '${heavy ? '  HEAVY (>${(warnTotalBytes / 1024 / 1024).toStringAsFixed(1)} MB)' : ''}',
    );
    if (offenders.isNotEmpty) {
      _log(
        '${offenders.length} offender(s) over '
        '${(warnBytes / 1024).toStringAsFixed(0)} KB:',
      );
      offenders.take(isFinal ? offenders.length : 5).forEach(_logEntry);
    }
    // Full per-image breakdown on the final log, for inspection.
    if (isFinal) sorted.forEach(_logEntry);
  }

  static void _logEntry(MapEntry<String, int> e) =>
      _log('  ${(e.value / 1024).toStringAsFixed(1).padLeft(8)} KB  ${e.key}');

  static void _log(String message) => MediaLog.line(MediaLog.bytes, message);
}
