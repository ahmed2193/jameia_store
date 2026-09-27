import 'dart:async';
import 'dart:convert';

import 'package:hero_mart/src/core/storage/cache_key.dart';
import 'package:hero_mart/src/core/storage/cache_namespace.dart';
import 'package:hero_mart/src/core/storage/json_cache_store.dart';

/// A [JsonCacheStore] in memory: entries round-trip through JSON (like the
/// file store), [readGate] holds reads, and the calls are counted.
class InMemoryJsonCacheStore implements JsonCacheStore {
  final Map<String, (CacheKey, CachedJson)> entries = {};
  Completer<void>? readGate;
  int reads = 0;
  int writes = 0;
  int removes = 0;

  /// Saves [data] under [key] as if a load had written it at [savedAt].
  void seed(CacheKey key, Object data, DateTime savedAt) =>
      entries[key.full] = (key, CachedJson(data: _copy(data), savedAt: savedAt));

  CachedJson? entryOf(CacheKey key) => entries[key.full]?.$2;

  static Object _copy(Object data) => jsonDecode(jsonEncode(data)) as Object;

  @override
  Future<CachedJson?> read(CacheKey key) async {
    reads++;
    await readGate?.future;
    return entries[key.full]?.$2;
  }

  @override
  Future<void> write(
    CacheKey key,
    Object data, {
    required DateTime savedAt,
  }) async {
    writes++;
    seed(key, data, savedAt);
  }

  @override
  Future<void> remove(CacheKey key) async {
    removes++;
    entries.remove(key.full);
  }

  @override
  Future<void> removeNamespace(CacheNamespace namespace) async {
    removes++;
    entries.removeWhere((_, entry) => entry.$1.namespace == namespace);
  }

  @override
  Future<void> removeOwnedEntries() async => entries.removeWhere(
    (_, entry) => entry.$1.bucket == CacheKey.customerBucket,
  );

  @override
  Future<void> clear() async => entries.clear();
}

/// A public, 60 s fresh / 7 d namespace for tests.
const CacheNamespace testNamespace = CacheNamespace(
  'test.items',
  scope: CacheScope.public,
  freshFor: Duration(seconds: 60),
  maxAge: Duration(days: 7),
);
