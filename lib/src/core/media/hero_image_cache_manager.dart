import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import 'image_disk_index.dart';
import 'image_disk_seed.dart';
import 'image_prefetcher.dart';
import 'image_variant_index.dart';
import 'indexed_json_cache_info_repository.dart';
import 'media_log.dart';
import 'timeout_http_file_service.dart';

export 'image_body_stalled_exception.dart';

/// Shared singleton disk cache for every network image. A 365-day stale
/// window means a fetched image effectively never re-downloads for the app's
/// practical life — the disk entry survives app close/relaunch, so "a loaded
/// image stays loaded" holds across sessions. (Freshness itself comes from
/// the CDN's `Cache-Control: max-age=31536000`; the stale period only drives
/// the store's cleanup of untouched files.)
///
/// Its metadata repository ([IndexedJsonCacheInfoRepository]) answers key
/// lookups in O(1) and keeps [ImageDiskIndex] in step with the store's
/// cleanup; its file service ([TimeoutHttpFileService]) times out stalled
/// headers and bodies and marks the disk index once a file is really there.
class HeroImageCacheManager {
  HeroImageCacheManager._();

  static const String _key = 'heroAppImageCache';
  static const Duration _stalePeriod = Duration(days: 365);
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        _key,
        stalePeriod: _stalePeriod,
        // Disk-only cache (costs disk, not RAM). ~60 KB/image × 10000 ≈ 600 MB
        // worst-case — acceptable on modern devices, keeps a year of browsing
        // history hot for instant, network-free reload.
        maxNrOfCacheObjects: 10000,
        repo: IndexedJsonCacheInfoRepository(databaseName: _key),
        fileService: TimeoutHttpFileService(),
      ),
    );
    return _instance!;
  }

  /// The manager images load (and evict) through: [instance], unless a test
  /// installed [debugLoaderOverride].
  static BaseCacheManager get loader => debugLoaderOverride ?? instance;

  /// Test seam: a fake manager for image loads and retry evictions.
  @visibleForTesting
  static BaseCacheManager? debugLoaderOverride;

  /// The image file service with [client] injected (tests only).
  @visibleForTesting
  static FileService debugFileService(http.Client client) =>
      TimeoutHttpFileService(httpClient: client);

  /// The image store's metadata repository type, on a JSON file at [path]
  /// (tests only).
  @visibleForTesting
  static JsonCacheInfoRepository debugRepository(String path) =>
      IndexedJsonCacheInfoRepository(path: path);

  /// The keys [repo]'s O(1) lookup currently holds, or null when none is
  /// built (or [repo] is not the image store's type). Tests only.
  @visibleForTesting
  static Set<String>? debugIndexedKeys(JsonCacheInfoRepository repo) =>
      repo is IndexedJsonCacheInfoRepository ? repo.debugIndexedKeys : null;

  /// Seeds [ImageDiskIndex] with every still-valid key of the image store's
  /// metadata file, once per process. `main()` starts it (unawaited) right
  /// after the binding, so it lands before the first content frame; the
  /// first image decision starts it too, as a fallback. Safe that early: it
  /// reads the file itself ([ImageDiskSeed]) — no get_it, no Dio, no
  /// EasyLocalization, and not [instance].
  static Future<int> seedDiskIndex() =>
      ImageDiskIndex.instance.seedKeys(() => ImageDiskSeed.validKeys(_key));

  /// See [ImageDiskSeed.validKeysInJson].
  @visibleForTesting
  static List<String> validKeysInJson(String json, int nowMs) =>
      ImageDiskSeed.validKeysInJson(json, nowMs);

  /// Empties the disk cache, and forgets what the indexes knew of it.
  static Future<void> clearCache() async {
    ImageDiskIndex.instance.clear();
    ImageVariantIndex.instance.clear();
    try {
      await _instance?.emptyCache();
    } catch (e) {
      MediaLog.line(MediaLog.cache, 'clear error: $e');
    }
  }

  /// Removes the disk-cached entry for [keyOrUrl] (the `cacheKey` the entry
  /// was written under — the resolved URL by default). Safe when it doesn't
  /// exist.
  static Future<void> removeFile(String keyOrUrl) async {
    ImageDiskIndex.instance.remove(keyOrUrl);
    try {
      await (debugLoaderOverride ?? _instance)?.removeFile(keyOrUrl);
    } catch (e) {
      MediaLog.line(MediaLog.cache, 'remove error: $e');
    }
  }

  /// Warms the disk cache with [urls], each the EXACT variant a screen will
  /// request (the URL is the cacheKey). Delegates to
  /// [ImagePrefetcher.instance]: empty, duplicate, disk-known, recently
  /// failed and (per [isOnline]) offline URLs are skipped; the rest go to
  /// `downloadFile` (which joins an in-flight load of the same key) through
  /// [concurrency] (≤ 3) workers that wait for a quiet UI and network.
  /// Per-URL failures are swallowed. Completes when every URL is settled;
  /// cancelling [token] drops what is still queued.
  static Future<void> preCacheImages(
    List<String> urls, {
    int concurrency = 2,
    PrefetchToken? token,
    bool Function()? isOnline,
  }) async {
    if (urls.isEmpty) return;
    await ImagePrefetcher.instance.prefetch(
      urls,
      token: token ?? PrefetchToken(),
      concurrency: concurrency,
      isOnline: isOnline,
    );
  }
}
