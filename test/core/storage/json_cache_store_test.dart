// FileJsonCacheStore in a temp folder: round trip, format / namespace
// version mismatch → miss, corrupt file → miss + deleted, hash collision →
// miss, entry and total size caps (oldest first), per-namespace caps,
// removeOwnedEntries keeps public + guest, atomic writes (no temp file left,
// a crash leftover cleaned), off-isolate decoding of a large entry; and the
// FNV-1a key hash.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/storage/cache_key.dart';
import 'package:hero_mart/src/core/storage/cache_namespace.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';
import 'package:hero_mart/src/core/storage/json_cache_store.dart';

const CacheNamespace _items = CacheNamespace(
  'test.items',
  scope: CacheScope.public,
  freshFor: Duration(seconds: 60),
  maxAge: Duration(days: 7),
  maxEntries: 3,
);

CacheKey _key(
  String id, {
  CacheNamespace namespace = _items,
  String owner = CacheKey.publicOwner,
  String language = 'en',
}) => CacheKey(namespace: namespace, language: language, owner: owner, id: id);

final DateTime _t0 = DateTime.utc(2026, 9, 27, 10);

void main() {
  late Directory root;
  late FileJsonCacheStore store;

  FileJsonCacheStore storeWith({
    int maxBytes = FileJsonCacheStore.defaultMaxBytes,
    int maxEntryBytes = FileJsonCacheStore.defaultMaxEntryBytes,
    int isolateThreshold = FileJsonCacheStore.defaultIsolateThreshold,
  }) => FileJsonCacheStore(
    root: () async => root,
    maxBytes: maxBytes,
    maxEntryBytes: maxEntryBytes,
    isolateThreshold: isolateThreshold,
  );

  File fileOf(CacheKey key) => File(
    [root.path, key.bucket, key.namespace.name, '${key.fileName}.json']
        .join(Platform.pathSeparator),
  );

  List<File> filesUnder(Directory dir) => dir.existsSync()
      ? dir.listSync(recursive: true).whereType<File>().toList()
      : <File>[];

  setUp(() {
    root = Directory.systemTemp.createTempSync('json_cache_store_test');
    store = storeWith();
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('round trip: the results come back as saved, with savedAt', () async {
    final data = {
      'data': [
        {'_id': 'p1', 'name': 'Eggs', 'price': 2250},
      ],
      'pagination': {'page': 1, 'hasMore': false},
    };
    await store.write(_key('a'), data, savedAt: _t0);
    final entry = await store.read(_key('a'));
    expect(entry?.data, data);
    expect(entry?.savedAt, _t0);
    expect(entry?.savedAt.isUtc, isTrue);
  });

  test('a missing key is a miss', () async {
    expect(await store.read(_key('nope')), isNull);
  });

  test('language and owner are part of the key', () async {
    await store.write(_key('a'), {'lang': 'en'}, savedAt: _t0);
    expect(await store.read(_key('a', language: 'ar')), isNull);
    expect(await store.read(_key('a', owner: CacheOwner.guest)), isNull);
  });

  test('a namespace version bump → miss, and the old file is gone', () async {
    await store.write(_key('a'), {'x': 1}, savedAt: _t0);
    const bumped = CacheNamespace(
      'test.items',
      scope: CacheScope.public,
      freshFor: Duration(seconds: 60),
      maxAge: Duration(days: 7),
      version: 2,
    );
    // Same file (the hash covers the version, so point it there by hand).
    final oldFile = fileOf(_key('a'));
    final newKey = _key('a', namespace: bumped);
    await fileOf(newKey).parent.create(recursive: true);
    await oldFile.copy(fileOf(newKey).path);
    expect(await store.read(newKey), isNull);
    expect(fileOf(newKey).existsSync(), isFalse);
  });

  test('another format version → miss', () async {
    await store.write(_key('a'), {'x': 1}, savedAt: _t0);
    final file = fileOf(_key('a'));
    final record = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    record['v'] = FileJsonCacheStore.formatVersion + 1;
    file.writeAsStringSync(jsonEncode(record));
    expect(await store.read(_key('a')), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('a corrupt file → miss, and it is deleted', () async {
    final file = fileOf(_key('a'));
    await file.parent.create(recursive: true);
    file.writeAsStringSync('{"v": 1, "ns": "test.it');
    expect(await store.read(_key('a')), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('a hash collision (another key in the file) reads as a miss', () async {
    await store.write(_key('a'), {'x': 1}, savedAt: _t0);
    final file = fileOf(_key('a'));
    final record = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    record['key'] = _key('b').full;
    file.writeAsStringSync(jsonEncode(record));
    expect(await store.read(_key('a')), isNull);
  });

  test('an entry over the entry cap is not saved', () async {
    store = storeWith(maxEntryBytes: 256);
    await store.write(_key('big'), {'blob': 'x' * 1000}, savedAt: _t0);
    expect(await store.read(_key('big')), isNull);
    expect(filesUnder(root), isEmpty);
  });

  test('past its maxEntries a namespace drops its oldest entries', () async {
    for (var i = 0; i < 5; i++) {
      await store.write(
        _key('k$i'),
        {'i': i},
        savedAt: _t0.add(Duration(minutes: i)),
      );
    }
    expect(await store.read(_key('k0')), isNull);
    expect(await store.read(_key('k1')), isNull);
    for (var i = 2; i < 5; i++) {
      expect(await store.read(_key('k$i')), isNotNull, reason: 'k$i');
    }
  });

  test('past the total cap the oldest entries go first', () async {
    const wide = CacheNamespace(
      'test.wide',
      scope: CacheScope.public,
      freshFor: Duration(seconds: 60),
      maxAge: Duration(days: 7),
      maxEntries: 100,
    );
    final payload = {'blob': 'y' * 300};
    final one = utf8.encode(jsonEncode(payload)).length;
    store = storeWith(maxBytes: one * 4);
    for (var i = 0; i < 6; i++) {
      await store.write(
        _key('w$i', namespace: wide),
        payload,
        savedAt: _t0.add(Duration(minutes: i)),
      );
    }
    final kept = [
      for (var i = 0; i < 6; i++)
        if (await store.read(_key('w$i', namespace: wide)) != null) i,
    ];
    expect(kept.length, lessThan(6));
    expect(kept, isNotEmpty);
    expect(kept.last, 5, reason: 'the newest stays');
    expect(kept.first, greaterThan(0), reason: 'the oldest went first');
  });

  test('removeOwnedEntries wipes customers, keeps public and guest', () async {
    const personal = CacheNamespace(
      'test.personal',
      scope: CacheScope.owner,
      freshFor: Duration(seconds: 60),
      maxAge: Duration(days: 7),
    );
    final public = _key('p');
    final guest = _key('g', namespace: personal, owner: CacheOwner.guest);
    final customer = _key('c', namespace: personal, owner: 'c:42');
    for (final key in [public, guest, customer]) {
      await store.write(key, {'k': key.id}, savedAt: _t0);
    }
    await store.removeOwnedEntries();
    expect(await store.read(public), isNotNull);
    expect(await store.read(guest), isNotNull);
    expect(await store.read(customer), isNull);
    expect(
      Directory(
        [root.path, CacheKey.customerBucket].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
  });

  test('writes are atomic: no temp file is left behind', () async {
    await Future.wait([
      for (var i = 0; i < 10; i++)
        store.write(_key('same'), {'i': i}, savedAt: _t0),
    ]);
    final files = filesUnder(root);
    expect(files.where((f) => f.path.endsWith('.tmp')), isEmpty);
    expect(files, hasLength(1));
    expect((await store.read(_key('same')))?.data, {'i': 9}, reason: 'last wins');
  });

  test('a temp file left by a crash is cleaned on the next write', () async {
    final leftover = File('${fileOf(_key('a')).path}.7.tmp');
    await leftover.parent.create(recursive: true);
    leftover.writeAsStringSync('{"half": ');
    await store.write(_key('b'), {'x': 1}, savedAt: _t0);
    expect(leftover.existsSync(), isFalse);
  });

  test('a large entry is decoded off the UI isolate, same result', () async {
    store = storeWith(isolateThreshold: 64);
    final data = {
      'rows': [for (var i = 0; i < 50; i++) 'row $i'],
    };
    await store.write(_key('large'), data, savedAt: _t0);
    expect((await store.read(_key('large')))?.data, data);
  });

  test('clear deletes everything', () async {
    await store.write(_key('a'), {'x': 1}, savedAt: _t0);
    await store.clear();
    expect(await store.read(_key('a')), isNull);
    expect(root.existsSync(), isFalse);
  });

  test('an unusable folder never throws to the caller', () async {
    store = FileJsonCacheStore(root: () => Future.error(StateError('no dir')));
    expect(await store.read(_key('a')), isNull);
    await store.write(_key('a'), {'x': 1}, savedAt: _t0);
    await store.removeOwnedEntries();
  });

  group('CacheKey', () {
    test('FNV-1a 64 test vectors', () {
      expect(CacheKey.fnv1a64(''), 'cbf29ce484222325');
      expect(CacheKey.fnv1a64('a'), 'af63dc4c8601ec8c');
      expect(CacheKey.fnv1a64('foobar'), '85944171f73967e8');
    });

    test('buckets: public, guest, customer', () {
      expect(_key('x').bucket, 'public');
      expect(_key('x', owner: CacheOwner.guest).bucket, 'guest');
      expect(_key('x', owner: 'c:1').bucket, CacheKey.customerBucket);
    });
  });
}
