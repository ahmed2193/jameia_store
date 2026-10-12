import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show CacheObject;
import 'package:path_provider/path_provider.dart';

/// Reads the still-valid keys of the image store's metadata file for the
/// disk-index seed (`HeroImageCacheManager.seedDiskIndex`), without the store:
/// path_provider and file I/O only — no get_it, no Dio, and not the
/// `CacheManager`, whose store would parse the same file on the UI isolate.
///
/// The file is the one `JsonCacheInfoRepository(databaseName: name)` keeps
/// (flutter_cache_manager 3.4.3 json_cache_info_repository.dart:269-285:
/// `<application support dir>/<name>.json`), a JSON list of
/// `CacheObject.toMap()` maps (:231-237), read back through
/// [CacheObject.fromMap] like the repository's own `_readFile` (:140-168).
abstract final class ImageDiskSeed {
  /// Up to this size the file is read and parsed inline; past it (3–4 MB at
  /// 10 000 entries) on a background isolate.
  static const int inlineBytes = 50 * 1024;

  /// The keys of the metadata file of the store named [databaseName] whose
  /// `validTill` is still ahead; empty when there is no file yet.
  static Future<Iterable<String>> validKeys(String databaseName) async {
    final Directory dir = await getApplicationSupportDirectory();
    final String path =
        '${dir.path}${Platform.pathSeparator}$databaseName.json';
    final File file = File(path);
    if (!await file.exists()) return const <String>[];
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (await file.length() <= inlineBytes) {
      return validKeysInJson(await file.readAsString(), nowMs);
    }
    return _validKeysOffIsolate(path, nowMs);
  }

  // Its own function so the isolate closure captures only [path] and [nowMs].
  static Future<List<String>> _validKeysOffIsolate(String path, int nowMs) =>
      Isolate.run(() => validKeysInJson(File(path).readAsStringSync(), nowMs));

  /// The keys in [json] (the metadata file: a list of [CacheObject] maps)
  /// whose `validTill` is after [nowMs]. A malformed file reads as empty and
  /// a malformed entry is skipped: a missed key only costs a placeholder
  /// choice.
  static List<String> validKeysInJson(String json, int nowMs) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return const <String>[];
    }
    if (decoded is! List) return const <String>[];
    final List<String> keys = <String>[];
    for (final Object? e in decoded) {
      if (e is! Map<String, dynamic>) continue;
      try {
        final CacheObject o = CacheObject.fromMap(e);
        if (o.validTill.millisecondsSinceEpoch > nowMs) keys.add(o.key);
      } catch (_) {
        // skip the entry, keep the rest
      }
    }
    return keys;
  }
}
