import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import 'cache_key.dart';

/// A cached response as it was saved.
class CachedJson {
  const CachedJson({required this.data, required this.savedAt});

  /// The envelope's `results`, exactly as the server sent it.
  final Object data;

  /// When it was fetched (UTC).
  final DateTime savedAt;
}

/// The on-device store for API responses — the last data a screen showed,
/// kept for the next launch and for offline. Used only by cache datasources
/// (through `CacheSlot`s); never SharedPreferences, which is loaded whole into
/// memory at launch.
///
/// Nothing here throws to the caller: an unreadable entry is a miss (and is
/// deleted), a failed write is logged and forgotten.
abstract class JsonCacheStore {
  /// The entry saved under [key]; `null` for a miss — also for an entry of
  /// another format / namespace version, or one that does not decode (it is
  /// deleted).
  Future<CachedJson?> read(CacheKey key);

  /// Saves [data] (a decoded JSON value) under [key], stamped [savedAt].
  Future<void> write(CacheKey key, Object data, {required DateTime savedAt});

  Future<void> remove(CacheKey key);

  /// Deletes every entry of [namespace] — every language, id and owner: a
  /// change the customer made reached the server, so no saved copy of that
  /// data may be served as fresh any more.
  Future<void> removeNamespace(CacheNamespace namespace);

  /// Deletes every customer's entries (sign-out, session expiry); public
  /// and guest entries stay.
  Future<void> removeOwnedEntries();

  Future<void> clear();
}

/// [JsonCacheStore] as one JSON file per key under
/// `<cache dir>/api_cache/<bucket>/<namespace>/<fnv64>.json`, holding
/// `{ v, ns, nsv, key, savedAt, lang, owner, data }`.
///
///   * The folder is resolved on first use: app start never waits for it.
///   * Writes are atomic (a temp file, then a rename) and serialized; the
///     last write of a key wins.
///   * Files over [isolateThreshold] bytes are decoded off the UI isolate.
///   * An entry over [maxEntryBytes] is not saved; past [maxBytes] in total,
///     or past its namespace's `maxEntries`, the oldest entries go first.
///   * Logs name the namespace, the key hash and the size — never a payload.
class FileJsonCacheStore implements JsonCacheStore {
  FileJsonCacheStore({
    Future<Directory> Function()? root,
    this.maxBytes = defaultMaxBytes,
    this.maxEntryBytes = defaultMaxEntryBytes,
    this.isolateThreshold = defaultIsolateThreshold,
  }) : _rootOf = root ?? _defaultRoot;

  /// Bump when the record layout changes: every older file becomes a miss.
  static const int formatVersion = 1;

  static const int defaultMaxBytes = 12 * 1024 * 1024;
  static const int defaultMaxEntryBytes = 1024 * 1024;
  static const int defaultIsolateThreshold = 64 * 1024;

  static const String logName = 'cache';
  static const String folderName = 'api_cache';
  static const String _suffix = '.json';
  static const String _tempSuffix = '.tmp';

  static const String _versionField = 'v';
  static const String _namespaceField = 'ns';
  static const String _namespaceVersionField = 'nsv';
  static const String _keyField = 'key';
  static const String _savedAtField = 'savedAt';
  static const String _languageField = 'lang';
  static const String _ownerField = 'owner';
  static const String _dataField = 'data';

  final int maxBytes;
  final int maxEntryBytes;
  final int isolateThreshold;
  final Future<Directory> Function() _rootOf;

  Future<Directory>? _root;
  Map<String, _IndexEntry>? _index;
  Future<void> _tail = Future<void>.value();
  int _tempSequence = 0;

  static Future<Directory> _defaultRoot() async {
    final cache = await getApplicationCacheDirectory();
    return Directory('${cache.path}${Platform.pathSeparator}$folderName');
  }

  Future<Directory> get _dir => _root ??= _rootOf();

  static String _join(List<String> parts) => parts.join(Platform.pathSeparator);

  Future<File> _fileOf(CacheKey key) async => File(
    _join([
      (await _dir).path,
      key.bucket,
      key.namespace.name,
      '${key.fileName}$_suffix',
    ]),
  );

  @override
  Future<CachedJson?> read(CacheKey key) async {
    try {
      final file = await _fileOf(key);
      if (!await file.exists()) return null;
      final path = file.path;
      final Object? record = await file.length() > isolateThreshold
          ? await Isolate.run(() => _decodeFile(path))
          : jsonDecode(await file.readAsString());
      final entry = _entryOf(record, key);
      if (entry != null) return entry;
      _log('dropped', key, 'another format or key');
    } on Object catch (error) {
      _log('dropped', key, 'unreadable (${error.runtimeType})');
    }
    await remove(key);
    return null;
  }

  static Object? _decodeFile(String path) =>
      jsonDecode(File(path).readAsStringSync());

  static CachedJson? _entryOf(Object? record, CacheKey key) {
    if (record is! Map<String, dynamic>) return null;
    final savedAt = record[_savedAtField];
    final data = record[_dataField];
    final matches =
        record[_versionField] == formatVersion &&
        record[_namespaceField] == key.namespace.name &&
        record[_namespaceVersionField] == key.namespace.version &&
        record[_keyField] == key.full &&
        savedAt is int &&
        data != null;
    if (!matches) return null;
    return CachedJson(
      data: data,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt, isUtc: true),
    );
  }

  @override
  Future<void> write(CacheKey key, Object data, {required DateTime savedAt}) =>
      _serial('write', key, () async {
        final bytes = utf8.encode(
          jsonEncode(<String, Object?>{
            _versionField: formatVersion,
            _namespaceField: key.namespace.name,
            _namespaceVersionField: key.namespace.version,
            _keyField: key.full,
            _savedAtField: savedAt.toUtc().millisecondsSinceEpoch,
            _languageField: key.language,
            _ownerField: key.owner,
            _dataField: data,
          }),
        );
        if (bytes.length > maxEntryBytes) {
          _log('skipped', key, '${bytes.length}B > entry cap');
          return;
        }
        final file = await _fileOf(key);
        await file.parent.create(recursive: true);
        final temp = File('${file.path}.${_tempSequence++}$_tempSuffix');
        await temp.writeAsBytes(bytes, flush: true);
        await temp.rename(file.path);
        final index = await _indexOf();
        index[file.path] = _IndexEntry(
          namespace: key.namespace.name,
          bucket: key.bucket,
          bytes: bytes.length,
          savedAt: savedAt,
        );
        await _evict(index, key);
        _log('saved', key, '${bytes.length}B');
      });

  @override
  Future<void> remove(CacheKey key) => _serial('remove', key, () async {
    final file = await _fileOf(key);
    if (await file.exists()) await file.delete();
    _index?.remove(file.path);
  });

  @override
  Future<void> removeNamespace(CacheNamespace namespace) =>
      _serial('forget', null, () async {
        final root = await _dir;
        if (!await root.exists()) return;
        await for (final bucket in root.list()) {
          if (bucket is! Directory) continue;
          final folder = Directory(_join([bucket.path, namespace.name]));
          if (await folder.exists()) await folder.delete(recursive: true);
        }
        _index?.removeWhere((_, entry) => entry.namespace == namespace.name);
        log('${namespace.name} forgotten', name: logName);
      });

  @override
  Future<void> removeOwnedEntries() => _serial('wipe', null, () async {
    final owned = Directory(
      _join([(await _dir).path, CacheKey.customerBucket]),
    );
    if (await owned.exists()) await owned.delete(recursive: true);
    _index?.removeWhere((_, entry) => entry.bucket == CacheKey.customerBucket);
    log('customer entries wiped', name: logName);
  });

  @override
  Future<void> clear() => _serial('clear', null, () async {
    final root = await _dir;
    if (await root.exists()) await root.delete(recursive: true);
    _index?.clear();
    log('cleared', name: logName);
  });

  /// Runs [action] after every earlier write / removal; logs its failure.
  Future<void> _serial(
    String what,
    CacheKey? key,
    Future<void> Function() action,
  ) {
    final run = _tail.then((_) => action()).catchError((Object error) {
      _log('$what failed', key, '${error.runtimeType}');
    });
    return _tail = run;
  }

  /// What is on disk, read once (on the first write) and kept in step after.
  Future<Map<String, _IndexEntry>> _indexOf() async {
    final known = _index;
    if (known != null) return known;
    final index = <String, _IndexEntry>{};
    final root = await _dir;
    if (await root.exists()) {
      await for (final entity in root.list(recursive: true)) {
        if (entity is! File) continue;
        if (entity.path.endsWith(_tempSuffix)) {
          // Left by a write the process did not finish.
          await entity.delete();
          continue;
        }
        if (!entity.path.endsWith(_suffix)) continue;
        final parts = entity.path.split(Platform.pathSeparator);
        final stat = await entity.stat();
        index[entity.path] = _IndexEntry(
          namespace: parts[parts.length - 2],
          bucket: parts[parts.length - 3],
          bytes: stat.size,
          savedAt: stat.modified,
        );
      }
    }
    return _index = index;
  }

  /// The oldest entries go first: past the namespace's `maxEntries`, then
  /// past [maxBytes] in total.
  Future<void> _evict(Map<String, _IndexEntry> index, CacheKey key) async {
    final byAge = index.entries.toList()
      ..sort((a, b) => a.value.savedAt.compareTo(b.value.savedAt));
    final namespace = key.namespace;
    var inNamespace = byAge
        .where((entry) => entry.value.namespace == namespace.name)
        .length;
    var total = byAge.fold<int>(0, (sum, entry) => sum + entry.value.bytes);
    for (final entry in byAge) {
      final overNamespace =
          entry.value.namespace == namespace.name &&
          inNamespace > namespace.maxEntries;
      if (!overNamespace && total <= maxBytes) continue;
      final file = File(entry.key);
      if (await file.exists()) await file.delete();
      index.remove(entry.key);
      total -= entry.value.bytes;
      if (entry.value.namespace == namespace.name) inNamespace--;
      log(
        'evicted ${entry.value.namespace} ${entry.value.bytes}B',
        name: logName,
      );
    }
  }

  static void _log(String what, CacheKey? key, String detail) => log(
    key == null
        ? '$what: $detail'
        : '$what ${key.namespace.name} ${key.fileName}: $detail',
    name: logName,
  );
}

class _IndexEntry {
  const _IndexEntry({
    required this.namespace,
    required this.bucket,
    required this.bytes,
    required this.savedAt,
  });

  final String namespace;
  final String bucket;
  final int bytes;
  final DateTime savedAt;
}
