import 'dart:collection';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Adds a per-request timeout to [HttpFileService] so a stalled connection
/// can't leave a [JameiaImage] stuck on its placeholder forever.
class _TimeoutHttpFileService extends HttpFileService {
  // 25 s — long enough that a slow CDN handshake on 3G cold-start doesn't
  // time out and mass-fail URLs; short enough that a truly dead socket gives
  // up and lets the retry loop reschedule.
  static const Duration _timeout = Duration(seconds: 25);

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    return super
        .get(url, headers: headers)
        .timeout(
          _timeout,
          onTimeout: () => throw http.ClientException(
            'Image download timed out after ${_timeout.inSeconds}s',
            Uri.parse(url),
          ),
        );
  }
}

/// Shared singleton disk cache for every [JameiaImage]. A 365-day stale window
/// means a fetched image effectively never re-downloads for the app's
/// practical life — the disk entry survives app close/relaunch, so "a loaded
/// image stays loaded" holds across sessions.
class JameiaImageCacheManager {
  JameiaImageCacheManager._();

  static const String _key = 'jameiaAppImageCache';
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
        repo: JsonCacheInfoRepository(databaseName: _key),
        fileService: _TimeoutHttpFileService(),
      ),
    );
    return _instance!;
  }

  static Future<void> clearCache() async {
    try {
      await _instance?.emptyCache();
    } catch (e) {
      log('clear error: $e', name: 'JameiaImageCache');
    }
  }

  /// Removes the disk-cached entry for [keyOrUrl]. Safe when it doesn't exist.
  static Future<void> removeFile(String keyOrUrl) async {
    try {
      await _instance?.removeFile(keyOrUrl);
    } catch (e) {
      log('remove error: $e', name: 'JameiaImageCache');
    }
  }

  /// Pre-download a batch of URLs to the disk cache. Concurrency capped at 4
  /// to avoid 40 parallel TLS handshakes on a cold start; per-URL failures are
  /// swallowed so one 404 doesn't abort the batch.
  static Future<void> preCacheImages(
    List<String> urls, {
    int concurrency = 4,
  }) async {
    if (urls.isEmpty) return;
    final seen = <String>{};
    final queue = Queue<String>();
    for (final u in urls) {
      if (u.isEmpty) continue;
      if (seen.add(u)) queue.add(u);
    }
    if (queue.isEmpty) return;

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final url = queue.removeFirst();
        try {
          await instance.downloadFile(url);
        } catch (_) {
          /* per-url failures non-fatal */
        }
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, queue.length),
      (_) => worker(),
    );
    await Future.wait(workers);
  }

  static Future<CacheInfo> getCacheInfo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/$_key');
      int fileCount = 0;
      int totalBytes = 0;
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            fileCount++;
            try {
              totalBytes += (await entity.stat()).size;
            } catch (_) {}
          }
        }
      }
      return CacheInfo(
        fileCount: fileCount,
        totalSizeInMB: totalBytes / (1024 * 1024),
      );
    } catch (e) {
      log('info error: $e', name: 'JameiaImageCache');
      return const CacheInfo(fileCount: 0, totalSizeInMB: 0.0);
    }
  }
}

class CacheInfo {
  final int fileCount;
  final double totalSizeInMB;
  const CacheInfo({required this.fileCount, required this.totalSizeInMB});
  String get formattedSize => '${totalSizeInMB.toStringAsFixed(2)} MB';
}
