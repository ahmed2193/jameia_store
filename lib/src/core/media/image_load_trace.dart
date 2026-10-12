import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show HttpExceptionWithStatus;

import 'hero_image_cache_manager.dart';
import 'image_bytes_tracker.dart';
import 'image_disk_index.dart';
import 'image_load_trace_stats.dart';
import 'image_ram_key.dart';
import 'media_log.dart';

/// Debug-only `[IMGCACHE]` trace: each image load by source and by "seen"
/// (built earlier in this process). Hooks are no-ops unless `kDebugMode &&
/// enabled` (`--dart-define=IMGCACHE_TRACE=true`). Lines go to the VM log
/// under `IMGCACHE` ([MediaLog]).
///
/// Source = status of the exact RAM key ([memoryKey]): keepAlive/live is
/// memory (sync frame), pending is inflight, else disk?/network? settled by an
/// async `getFileFromCache` (`resolve` line). `policy=` is the transition plan
/// the tile took (ram|disk|variant|network, image_load_policy.dart). Fade is
/// detected, not derived: octo_image 2.1.0 image_handler.dart:241-247 returns
/// a sync frame bare, but an async frame lands in `_stack`, which re-calls the
/// placeholder builder while fading in. A placeholder call that finds the RAM
/// key complete is that landing build. No imageBuilder, no stream listener.
class ImageLoadTrace {
  ImageLoadTrace._();

  static bool _on = kDebugMode && const bool.fromEnvironment('IMGCACHE_TRACE');

  /// Master switch. [ImageBytesTracker.enabled] also turns it on.
  static bool get enabled => kDebugMode && (_on || ImageBytesTracker.enabled);
  static set enabled(bool value) => _on = value;

  /// Test seams: sync disk-metadata probe and async disk lookup (validTill).
  @visibleForTesting
  static bool Function(String) diskHint = (String k) =>
      ImageDiskIndex.instance.contains(k) ||
      HeroImageCacheManager.instance.store.memoryCacheContainsKey(k);
  @visibleForTesting
  static Future<DateTime?> Function(String) diskLookup = (String k) async =>
      (await HeroImageCacheManager.instance.getFileFromCache(k))?.validTill;

  static final Set<String> _seenAssets = <String>{}; // process lifetime
  static final Map<String, bool> _seenAtBuild = <String, bool>{};
  static final Expando<String> _owners = Expando<String>();
  static final Expando<_Site> _sites = Expando<_Site>();
  static int _gen = 0;

  /// From the image state's build; [owner] (its Element) dedupes rebuilds;
  /// [policy] is the tile's `ImageLoadSource` name.
  static void onBuild(
    Object owner,
    String url,
    String key,
    int? w,
    int? h,
    double? siteW,
    double? siteH, {
    String? policy,
  }) {
    if (!kDebugMode || !enabled) return;
    if (_owners[owner] == key) return ImageTraceStats.bump('rebuilds');
    _owners[owner] = key;
    final String base = url.split('?').first;
    final bool seen = !_seenAssets.add(base);
    if (_seenAtBuild.length > 1024) _seenAtBuild.clear();
    _seenAtBuild[key] = seen;
    ImageTraceStats.variant(base, key);
    ImageTraceStats.bump('mounts', seen);
    if (policy != null) ImageTraceStats.bump('policy.$policy', seen);
    final ImageCacheStatus st = memoryStatus(key, w, h);
    final String? hit = imageRamLanded(st)
        ? 'mem'
        : (st.pending ? 'inflight' : null);
    if (hit != null) ImageTraceStats.bump(hit, seen);
    final String src = hit == 'mem'
        ? 'memory'
        : hit ?? (diskHint(key) ? 'disk?' : 'network?');
    _log(
      'build src=$src seen=${_b(seen)} key=$key mem=${w ?? 'src'}x'
      '${h ?? 'src'} site=${siteW?.round()}x${siteH?.round()} '
      'policy=${policy ?? '-'}',
    );
    if (hit != null) return;
    final int gen = _gen;
    Future<DateTime?>.sync(() => diskLookup(key)).then((DateTime? t) {
      if (gen != _gen || !enabled) return;
      final bool stale = t != null && t.isBefore(DateTime.now());
      ImageTraceStats.bump(t == null ? 'net' : 'disk', seen);
      if (stale) ImageTraceStats.bump('stale', seen);
      _log(
        'resolve key=$key src=${t == null ? 'network' : 'disk'}'
        '${stale ? '-stale' : ''}',
      );
    }, onError: (Object e) => _log('resolve key=$key src=unknown ($e)'));
  }

  /// From the placeholder builder of one image state. A first-attempt
  /// placeholder of a `disk` / `variant` [policy] is a still box or the cached
  /// variant, counted as `placeholder_<policy>`, not `shimmer`.
  static void onPlaceholder(
    Object site,
    String key,
    int? w,
    int? h,
    int attempt,
    Duration fadeIn, {
    String? policy,
  }) {
    if (!kDebugMode || !enabled) return;
    final _Site s = _site(site, key);
    if (s.shimmerAt != attempt) {
      final bool quiet =
          attempt == 0 && (policy == 'disk' || policy == 'variant');
      final String name = s.shimmerAt >= 0
          ? 'shimmer_retry'
          : (quiet ? 'placeholder_$policy' : 'shimmer');
      s.shimmerAt = attempt;
      ImageTraceStats.bump(name, s.seen);
      _log('$name key=$key seen=${_b(s.seen)} attempt=$attempt');
    }
    if (s.fadeAt == attempt || fadeIn <= Duration.zero) return;
    if (!imageRamLanded(memoryStatus(key, w, h))) return;
    s.fadeAt = attempt;
    ImageTraceStats.bump('fade', s.seen);
    _log('fade key=$key seen=${_b(s.seen)} ms=${fadeIn.inMilliseconds}');
  }

  /// From the errorWidget builder; counted once per attempt.
  static void onFail(Object site, String key, int attempt, Object? error) {
    if (!kDebugMode || !enabled) return;
    final _Site s = _site(site, key);
    if (s.failAt == attempt) return;
    s.failAt = attempt;
    ImageTraceStats.bump('fail', s.seen);
    final Object code = error is HttpExceptionWithStatus
        ? error.statusCode
        : 'none';
    _log('fail key=$key status=$code attempt=$attempt');
  }

  /// Every call is one real HTTP request (`TimeoutHttpFileService.get`).
  static void onNetworkGet(String url) {
    if (!kDebugMode || !enabled) return;
    _log('net GET $url n=${ImageTraceStats.get(url)}');
  }

  /// The disk-index seed turned a tile still waiting on [from] (`network`)
  /// into [to] (`disk`), in place (`ImageLoadPolicy.afterSeed`). Its policy
  /// count moves, and so does a first-attempt `shimmer` count (the still box
  /// of a network decision) to `placeholder_<to>`.
  static void onRedecide(
    Object site,
    String key, {
    required String from,
    required String to,
  }) {
    if (!kDebugMode || !enabled) return;
    final bool seen = _seenAtBuild[key] ?? false;
    ImageTraceStats.move('policy.$from', 'policy.$to', seen);
    final _Site? s = _sites[site];
    if (s != null && s.key == key && s.shimmerAt == 0) {
      ImageTraceStats.move('shimmer', 'placeholder_$to', seen);
    }
    ImageTraceStats.bump('redecide', seen);
    _log('redecide key=$key seen=${_b(seen)} policy=$to from=$from cause=seed');
  }

  /// One LRU trim of `TrimmingImageCache` (memory pressure): what it evicted
  /// and how long the eviction took.
  static void onTrim({
    required int entriesBefore,
    required int entriesAfter,
    required int bytesBefore,
    required int bytesAfter,
    required int live,
    required Duration took,
  }) {
    if (!kDebugMode || !enabled) return;
    ImageTraceStats.bump('trim');
    _log(
      'trim evicted=${entriesBefore - entriesAfter} entries '
      '${((bytesBefore - bytesAfter) / 1024).round()} KB '
      '($entriesBefore→$entriesAfter, $bytesBefore→$bytesAfter B) '
      'live=$live us=${took.inMicroseconds}',
    );
  }

  /// View-model lifecycle line on the same switch: `[VMLIFE] <vm> <event>`.
  static void logVm(String vmName, String event) {
    if (kDebugMode && enabled) MediaLog.line(MediaLog.vmLife, '$vmName $event');
  }

  /// Exact RAM key of `CachedNetworkImage(cacheKey:, memCacheWidth/Height:)`
  /// (image_ram_key.dart).
  @visibleForTesting
  static Object memoryKey(String key, int? w, int? h) => imageRamKey(key, w, h);

  static ImageCacheStatus memoryStatus(String key, int? w, int? h) =>
      imageRamStatus(key, w, h);

  /// Clears the scenario counters. The "seen" set lives for the process.
  static void reset() {
    ImageTraceStats.reset();
    _gen++;
    if (kDebugMode && enabled) _log('RESET');
  }

  static String summary() => ImageTraceStats.summary();
  static Map<String, Object> snapshot() => ImageTraceStats.snapshot();
  static String imageCacheStats() => ImageTraceStats.imageCacheStats();

  // One record per placeholder site AND key: a tile whose URL changes in place
  // (same State, new cacheKey) starts a fresh record.
  static _Site _site(Object site, String key) {
    final _Site? s = _sites[site];
    if (s != null && s.key == key) return s;
    return _sites[site] = _Site(_seenAtBuild[key] ?? false, key);
  }

  static void _log(String m) => MediaLog.line(MediaLog.trace, m);
  static String _b(bool v) => v ? '1' : '0';
}

class _Site {
  _Site(this.seen, this.key);
  final bool seen;
  final String key;
  int shimmerAt = -1, fadeAt = -1, failAt = -1;
}
