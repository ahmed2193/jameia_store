import 'dart:developer';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Adds a per-request timeout to [HttpFileService] so a stalled connection
/// can't leave a [HeroImage] stuck on its placeholder forever.
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

/// Shared singleton disk cache for every [HeroImage]. A 365-day stale window
/// means a fetched image effectively never re-downloads for the app's
/// practical life — the disk entry survives app close/relaunch, so "a loaded
/// image stays loaded" holds across sessions.
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
      log('clear error: $e', name: 'HeroImageCache');
    }
  }

  /// Removes the disk-cached entry for [keyOrUrl]. Safe when it doesn't exist.
  static Future<void> removeFile(String keyOrUrl) async {
    try {
      await _instance?.removeFile(keyOrUrl);
    } catch (e) {
      log('remove error: $e', name: 'HeroImageCache');
    }
  }
}
