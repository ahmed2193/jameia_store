import 'dart:async';

import 'package:flutter/foundation.dart'
    show ValueListenable, ValueNotifier, kDebugMode, visibleForTesting;
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show CacheObject;

import 'media_log.dart';

/// Process-wide set of image cacheKeys known to be on disk, answered
/// synchronously ([contains]) so a mounting image can choose its placeholder
/// and fade before the asynchronous disk lookup runs.
///
/// flutter_cache_manager's only sync probe, `store.memoryCacheContainsKey`,
/// knows just the keys this process has touched; a cold start knows none.
/// This index adds the rest, fed by:
///  * [seedKeys] / [seed]: ONCE per process, from `main()`, every key of the
///    disk-metadata file whose `validTill` is still ahead (the CDN sends
///    `max-age=31536000`, so in practice every CDN file). [seeded] turns true
///    when it is done, so a tile that mounted before it can re-check;
///  * [markDownloaded]: the file service, when a download's body completed
///    (or a 304 kept the file). The service sees URLs, not keys: the URL IS
///    the key except on the EXIF raw fallback, which fetches the canonical URL
///    into the variant's key — that tile registers the pair via
///    [expectDownload] first;
///  * [markSeen]: a build that found the RAM key complete (the bytes came off
///    disk under that key).
/// [remove] drops a key the retry machine deletes from disk, and every key
/// the store's own cleanup (capacity / stale period) is about to delete.
///
/// A wrong "yes" (file purged by the OS since the seed) only costs the
/// placeholder choice: the tile then shows its still box until the late
/// shimmer, never a broken image. Bounded: past [maxKeys] (the store's 10 000
/// files plus headroom for the keys cleanup has yet to drop) it starts over.
/// A static singleton ([instance]); never in get_it.
class ImageDiskIndex {
  ImageDiskIndex({this.maxKeys = 12500, this.maxPendingUrls = 256});

  static final ImageDiskIndex instance = ImageDiskIndex();

  final int maxKeys;
  final int maxPendingUrls;

  static const int _kSeedChunk = 1000;

  final Set<String> _keys = <String>{};
  final Map<String, Set<String>> _keysByUrl = <String, Set<String>>{};
  Future<int>? _seeding;

  /// Whether [cacheKey] is known to be on disk.
  bool contains(String cacheKey) => _keys.contains(cacheKey);

  int get length => _keys.length;

  /// A build found [cacheKey] complete in RAM, so its file exists.
  void markSeen(String cacheKey) => _add(cacheKey);

  /// [cacheKey]'s file was deleted (retry eviction) or is about to be (store
  /// cleanup).
  void remove(String cacheKey) => _keys.remove(cacheKey);

  /// The next download of [url] lands under [cacheKey] (raw fallback). A no-op
  /// when they are equal, which is every other load.
  void expectDownload(String url, String cacheKey) {
    if (url == cacheKey) return;
    if (_keysByUrl.length >= maxPendingUrls && !_keysByUrl.containsKey(url)) {
      _keysByUrl.clear();
    }
    (_keysByUrl[url] ??= <String>{}).add(cacheKey);
  }

  /// A download of [url] is on disk: marks the keys registered for it by
  /// [expectDownload], or [url] itself (url == key).
  void markDownloaded(String url) {
    final Set<String>? keys = _keysByUrl.remove(url);
    if (keys == null) {
      _add(url);
    } else {
      keys.forEach(_add);
    }
  }

  /// False until the seed has finished (or failed), then true for good. A
  /// tile that decided `network` before it listens once and re-checks
  /// (`ImageLoadPolicy.afterSeed`).
  ValueListenable<bool> get seeded => _seeded;
  final ValueNotifier<bool> _seeded = ValueNotifier<bool>(false);

  /// Adds every key [validKeys] lists (already filtered to still-valid ones).
  /// Runs once per process, shared with [seed] (later calls return the first
  /// run's future), yields to the event loop every [_kSeedChunk] keys, and
  /// never throws: a failure leaves the index to the other feeds. Completes
  /// with the number of keys added.
  Future<int> seedKeys(Future<Iterable<String>> Function() validKeys) =>
      _seeding ??= _seed(validKeys);

  /// [seedKeys] from repository objects: the ones whose `validTill` is after
  /// [now].
  Future<int> seed(
    Future<Iterable<CacheObject>> Function() source, {
    DateTime Function()? now,
  }) {
    final DateTime Function() clock = now ?? DateTime.now;
    return seedKeys(() async {
      final Iterable<CacheObject> objects = await source();
      final DateTime t = clock();
      return objects
          .where((CacheObject o) => o.validTill.isAfter(t))
          .map((CacheObject o) => o.key);
    });
  }

  Future<int> _seed(Future<Iterable<String>> Function() source) async {
    try {
      final Iterable<String> keys = await source();
      int added = 0, seen = 0;
      for (final String key in keys) {
        if (_add(key)) added++;
        if (++seen % _kSeedChunk == 0) {
          await Future<void>.delayed(Duration.zero); // yield to frames
        }
      }
      _debugLog('seeded $added of $seen');
      return added;
    } catch (e) {
      _debugLog('seed failed: $e');
      return 0;
    } finally {
      _seeded.value = true;
    }
  }

  /// Forgets every key (the disk cache was emptied).
  void clear() {
    _keys.clear();
    _keysByUrl.clear();
  }

  @visibleForTesting
  void reset() {
    clear();
    _seeding = null;
    _seeded.value = false;
  }

  bool _add(String key) {
    if (key.isEmpty) return false;
    if (_keys.length >= maxKeys && !_keys.contains(key)) _keys.clear();
    return _keys.add(key);
  }

  static void _debugLog(String message) {
    if (kDebugMode) MediaLog.line(MediaLog.diskIndex, message);
  }
}
