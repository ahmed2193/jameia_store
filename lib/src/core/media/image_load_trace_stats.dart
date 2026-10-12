import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'media_log.dart';

/// Scenario counters and report lines behind `ImageLoadTrace`. Debug-only:
/// nothing in release calls into this class, so it is tree-shaken.
///
/// Counter names: mounts, mem, disk, net, inflight, stale, shimmer,
/// shimmer_retry, fade, fail, rebuilds, get; `policy.<source>` per mount
/// (ram, disk, variant, network — disk + variant are the shimmers avoided)
/// and `placeholder_disk` / `placeholder_variant` (a still box or a cached
/// variant shown instead of a shimmer); `redecide` (a network tile turned
/// disk by the late disk-index seed) and `trim` (an LRU trim on memory
/// pressure). A `seen.` prefix holds the same count limited to assets that
/// were already seen in this process.
class ImageTraceStats {
  ImageTraceStats._();

  static final Map<String, int> _c = <String, int>{};
  static final Map<String, int> _gets = <String, int>{};
  static final Map<String, Set<String>> _variants = <String, Set<String>>{};

  /// Adds 1 to [name], and to `seen.<name>` as well when [seen] is true.
  static void bump(String name, [bool seen = false]) {
    _c[name] = (_c[name] ?? 0) + 1;
    if (seen) _c['seen.$name'] = (_c['seen.$name'] ?? 0) + 1;
  }

  static int count(String name) => _c[name] ?? 0;

  /// Moves one count from [from] to [to] (a tile whose decision changed),
  /// `seen.` twins included when [seen]. A [from] already at 0 (a [reset]
  /// in between) stays at 0.
  static void move(String from, String to, [bool seen = false]) {
    void take(String k) {
      final int n = _c[k] ?? 0;
      if (n > 0) _c[k] = n - 1;
    }

    take(from);
    if (seen) take('seen.$from');
    bump(to, seen);
  }

  /// Records [variantKey] (a resolved URL or cacheKey) under its base asset.
  static void variant(String base, String variantKey) =>
      (_variants[base] ??= <String>{}).add(variantKey);

  /// Counts one HTTP GET of [url] and returns how many this scenario has seen.
  static int get(String url) {
    bump('get');
    return _gets[url] = (_gets[url] ?? 0) + 1;
  }

  /// Base assets that have more than two distinct variants (the budget is 2).
  static int get variantsOver2 =>
      _variants.values.where((Set<String> s) => s.length > 2).length;

  static void reset() {
    _c.clear();
    _gets.clear();
    _variants.clear();
  }

  /// The `[IMGCACHE] SUMMARY …` line (also logged, debug only).
  static String summary() {
    String f(String prefix, List<String> names) =>
        names.map((String k) => '$k=${count('$prefix$k')}').join(' ');
    const List<String> main = <String>[
      'mounts',
      'mem',
      'disk',
      'net',
      'shimmer',
      'fade',
      'fail',
    ];
    const List<String> more = <String>[
      'inflight',
      'stale',
      'shimmer_retry',
      'rebuilds',
      'policy.disk',
      'policy.variant',
      'get',
    ];
    final int dup = _gets.values.where((int n) => n > 1).length;
    return _report(
      'SUMMARY ${f('', main)} '
      '| seen: ${f('seen.', main.sublist(0, 6))} '
      '| assets=${_variants.length} variants>2=$variantsOver2 '
      '| ${f('', more)} dupGET=$dup',
    );
  }

  static Map<String, Object> snapshot() => <String, Object>{
    ..._c,
    'assets': _variants.length,
    'variantsOver2': variantsOver2,
    'variantsByAsset': <String, int>{
      for (final MapEntry<String, Set<String>> e in _variants.entries)
        e.key: e.value.length,
    },
    'getsByUrl': Map<String, int>.of(_gets),
  };

  /// The `[IMGCACHE] IMAGECACHE …` line (also logged, debug only).
  static String imageCacheStats() {
    final ImageCache c = PaintingBinding.instance.imageCache;
    return _report(
      'IMAGECACHE size=${c.currentSize}/${c.maximumSize} '
      'bytes=${c.currentSizeBytes}/${c.maximumSizeBytes} '
      'live=${c.liveImageCount} pending=${c.pendingImageCount}',
    );
  }

  static String _report(String body) {
    if (kDebugMode) MediaLog.line(MediaLog.trace, body);
    return MediaLog.format(MediaLog.trace, body);
  }
}
