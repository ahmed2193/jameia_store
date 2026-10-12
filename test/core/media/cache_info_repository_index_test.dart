// Locks the O(1) key lookup of the image store's metadata repository
// (IndexedJsonCacheInfoRepository + CacheObjectKeyMirror) on
// flutter_cache_manager 3.4.3:
//   * it is built when the first connection opens, dropped when the last one
//     closes, and untouched by a second connection or the disk-index seed;
//   * get() answers what the base JsonCacheInfoRepository answers, always: a
//     deleted object is never returned, an updated one comes back updated,
//     an object the index never saw is still found (miss -> base);
//   * insert -> delete -> get is null; updateOrInsert twice keeps one entry;
//     what the cleanup getters hand over leaves the index;
//   * a delete racing an unfinished insert, or a lookup, is not undone by
//     the late answer;
//   * the JSON on disk is byte-identical to the base repository's;
//   * a randomised run (inserts, updates, deletes, cleanups, awaited or not)
//     never makes the index disagree with the store;
//   * timing (printed, never asserted): 2 000 lookups on 10 000 objects.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';

const String _cdn = 'https://media.jm3eia.com';

String _key(int i) => '$_cdn/img$i.jpeg?w=225';

final DateTime _t0 = DateTime(2026, 10, 9, 12);

/// A fresh (id-less) object; [minutes] after [_t0] it was last touched.
CacheObject _obj(
  String key, {
  int? id,
  String? eTag,
  int minutes = 0,
  String? relativePath,
}) => CacheObject(
  key,
  relativePath: relativePath ?? '${key.hashCode}.file',
  validTill: _t0.add(const Duration(days: 300)),
  eTag: eTag,
  id: id,
  touched: _t0.add(Duration(minutes: minutes)),
);

/// Every field the store reads, as the repository writes it (touched
/// included): two objects with equal maps are interchangeable.
Map<String, dynamic> _fields(CacheObject? o) =>
    o?.toMap(setTouchedToNow: false) ?? const <String, dynamic>{};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  final List<JsonCacheInfoRepository> opened = <JsonCacheInfoRepository>[];

  setUpAll(
    () => tmp = Directory.systemTemp.createTempSync('hero_repo_index_test'),
  );
  tearDownAll(() {
    try {
      tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // best effort: Windows may still hold a handle
    }
  });
  setUp(ImageDiskIndex.instance.reset);
  tearDown(() async {
    for (final JsonCacheInfoRepository r in opened) {
      while (r.openConnections > 0) {
        await r.close();
      }
    }
    opened.clear();
    ImageDiskIndex.instance.reset();
  });

  Future<JsonCacheInfoRepository> openStore(String name) async {
    final JsonCacheInfoRepository repo = HeroImageCacheManager.debugRepository(
      '${tmp.path}/$name.json',
    );
    await repo.open();
    opened.add(repo);
    return repo;
  }

  Set<String>? indexedKeys(JsonCacheInfoRepository r) =>
      HeroImageCacheManager.debugIndexedKeys(r);

  group('lifecycle', () {
    test(
      'built on open from the stored file, dropped on the last close',
      () async {
        final File file = File('${tmp.path}/life.json');
        file.writeAsStringSync(
          jsonEncode(<Map<String, dynamic>>[
            for (int i = 0; i < 3; i++)
              _obj(_key(i), id: i + 1).toMap(setTouchedToNow: false),
          ]),
        );
        final JsonCacheInfoRepository repo =
            HeroImageCacheManager.debugRepository(file.path);
        expect(indexedKeys(repo), isNull, reason: 'nothing before open');

        await repo.open();
        opened.add(repo);
        expect(indexedKeys(repo), <String>{_key(0), _key(1), _key(2)});
        for (int i = 0; i < 3; i++) {
          final CacheObject? got = await repo.get(_key(i));
          expect(got?.id, i + 1);
          expect(got?.relativePath, '${_key(i).hashCode}.file');
        }

        // A second connection (any second reader) keeps the index.
        await repo.open();
        expect(indexedKeys(repo), hasLength(3));
        await repo.close();
        expect(indexedKeys(repo), hasLength(3), reason: 'a connection is left');

        await repo.close();
        expect(indexedKeys(repo), isNull, reason: 'last connection closed');
        expect(
          (await repo.get(_key(1)))?.id,
          2,
          reason: 'unindexed lookups still answer, from the base',
        );

        await repo.open();
        expect(indexedKeys(repo), hasLength(3), reason: 'rebuilt by open');
        expect((await repo.get(_key(2)))?.id, 3);
      },
    );

    test('a second connection keeps what the first indexed', () async {
      final JsonCacheInfoRepository repo = await openStore('second');
      final CacheObject a = await repo.insert(
        _obj(_key(1)),
        setTouchedToNow: false,
      );
      expect((await repo.get(_key(1)))?.id, a.id);
      final Set<String>? before = indexedKeys(repo);
      expect(before, <String>{_key(1)});

      await repo.open();
      await repo.getAllObjects();
      await repo.close();
      expect(indexedKeys(repo), before);
      expect(repo.openConnections, 1);
    });

    test('the store\'s manager uses the indexed type', () {
      expect(
        HeroImageCacheManager.debugIndexedKeys(
          JsonCacheInfoRepository(path: '${tmp.path}/plain.json'),
        ),
        isNull,
        reason: 'a plain repository has no index',
      );
    });
  });

  group('never returns what the store dropped', () {
    test('insert -> get -> delete -> get is null', () async {
      final JsonCacheInfoRepository repo = await openStore('del');
      final CacheObject stored = await repo.insert(
        _obj(_key(1)),
        setTouchedToNow: false,
      );
      expect(stored.id, isNotNull);
      expect(indexedKeys(repo), <String>{
        _key(1),
      }, reason: 'an unraced insert is indexed as soon as it resolves');

      final CacheObject? got = await repo.get(_key(1));
      expect(_fields(got), _fields(stored));

      expect(await repo.delete(stored.id!), 1);
      expect(indexedKeys(repo), isEmpty);
      expect(await repo.get(_key(1)), isNull);
      expect(await repo.getAllObjects(), isEmpty);
      expect(await repo.delete(stored.id!), 0, reason: 'already gone');
    });

    test(
      'deleteAll drops every id it is given and ignores unknown ones',
      () async {
        final JsonCacheInfoRepository repo = await openStore('delall');
        final List<CacheObject> stored = <CacheObject>[
          for (int i = 0; i < 4; i++)
            await repo.insert(_obj(_key(i)), setTouchedToNow: false),
        ];
        expect(indexedKeys(repo), hasLength(4));

        // A lazy iterable: it must be read once, not once per consumer.
        int reads = 0;
        final Iterable<int> ids = <int>[stored[0].id!, stored[2].id!, 9999].map(
          (int id) {
            reads++;
            return id;
          },
        );
        expect(await repo.deleteAll(ids), 2);
        expect(reads, 3);
        expect(await repo.get(_key(0)), isNull);
        expect(await repo.get(_key(2)), isNull);
        expect((await repo.get(_key(1)))?.id, stored[1].id);
        expect((await repo.get(_key(3)))?.id, stored[3].id);
        expect(indexedKeys(repo), <String>{_key(1), _key(3)});
      },
    );

    test('updateOrInsert twice keeps one entry, the second one wins', () async {
      final JsonCacheInfoRepository repo = await openStore('upsert');

      // id-less twice: the base keeps one entry per key (and one orphan id).
      final CacheObject first =
          await repo.updateOrInsert(_obj(_key(1), eTag: 'a')) as CacheObject;
      final CacheObject second =
          await repo.updateOrInsert(_obj(_key(1), eTag: 'b')) as CacheObject;
      expect(second.id, isNot(first.id));
      expect(await repo.getAllObjects(), hasLength(1));
      expect(indexedKeys(repo), <String>{_key(1)});
      expect((await repo.get(_key(1)))?.eTag, 'b');
      expect((await repo.get(_key(1)))?.id, second.id);

      // with the id it got: an update, same entry, new values.
      final Object? third = await repo.updateOrInsert(
        second.copyWith(eTag: 'c', relativePath: 'moved.file'),
      );
      expect(third, 1, reason: 'update returns its row count');
      expect(await repo.getAllObjects(), hasLength(1));
      expect(indexedKeys(repo), <String>{_key(1)});
      final CacheObject? got = await repo.get(_key(1));
      expect(got?.eTag, 'c');
      expect(got?.relativePath, 'moved.file');
      expect(got?.id, second.id);

      // the old id (an orphan in the base) deletes nothing, the live one does
      expect(await repo.delete(first.id!), 0);
      expect((await repo.get(_key(1)))?.eTag, 'c');
      expect(await repo.delete(second.id!), 1);
      expect(await repo.get(_key(1)), isNull);
    });

    test(
      'an update the index holds equals the store, touch time included',
      () async {
        final JsonCacheInfoRepository repo = await openStore('touch');
        final CacheObject stored = await repo.insert(
          _obj(_key(1), minutes: -5000),
          setTouchedToNow: false,
        );
        expect(stored.touched, _t0.add(const Duration(minutes: -5000)));

        // CacheStore touches every object it reads: update() with the default.
        await repo.updateOrInsert(stored);
        final CacheObject fromIndex = (await repo.get(_key(1)))!;
        final CacheObject fromStore = (await repo.getAllObjects()).single;
        expect(_fields(fromIndex), _fields(fromStore));
        expect(
          fromIndex.touched!.isAfter(stored.touched!),
          isTrue,
          reason: 'the touch was applied',
        );
      },
    );

    test('an update without an id is rejected exactly like the base', () async {
      final JsonCacheInfoRepository repo = await openStore('noid');
      await expectLater(repo.update(_obj(_key(1))), throwsArgumentError);
      await expectLater(repo.insert(_obj(_key(1), id: 7)), throwsArgumentError);
      expect(await repo.getAllObjects(), isEmpty);
      expect(await repo.get(_key(1)), isNull);
    });

    test(
      're-inserting a key under a new id: only the new id deletes it',
      () async {
        final JsonCacheInfoRepository repo = await openStore('reinsert');
        final CacheObject v1 = await repo.insert(
          _obj(_key(1), eTag: 'v1'),
          setTouchedToNow: false,
        );
        final CacheObject v2 = await repo.insert(
          _obj(_key(1), eTag: 'v2'),
          setTouchedToNow: false,
        );
        expect(v2.id, isNot(v1.id));
        expect((await repo.get(_key(1)))?.eTag, 'v2');

        expect(await repo.delete(v1.id!), 0, reason: 'v1 is no longer stored');
        expect((await repo.get(_key(1)))?.eTag, 'v2');
        expect(await repo.delete(v2.id!), 1);
        expect(await repo.get(_key(1)), isNull);
      },
    );
  });

  group('store cleanup', () {
    test(
      'getObjectsOverCapacity / getOldObjects results leave the index',
      () async {
        final JsonCacheInfoRepository repo = await openStore('cleanup');
        final DateTime now = DateTime.now();
        final Map<String, CacheObject> stored = <String, CacheObject>{};
        for (final (int i, Duration age) in <(int, Duration)>[
          (0, const Duration(days: 400)), // stale
          (1, const Duration(days: 10)), // least recently used of the rest
          (2, const Duration(hours: 1)),
          (3, const Duration(minutes: 1)),
        ]) {
          stored[_key(i)] = await repo.insert(
            CacheObject(
              _key(i),
              relativePath: '$i.file',
              validTill: now.add(const Duration(days: 300)),
              touched: now.subtract(age),
            ),
            setTouchedToNow: false,
          );
        }
        expect(indexedKeys(repo), hasLength(4));

        final List<CacheObject> old = await repo.getOldObjects(
          const Duration(days: 365),
        );
        expect(old.map((CacheObject o) => o.key), <String>[_key(0)]);
        expect(indexedKeys(repo), isNot(contains(_key(0))));

        final List<CacheObject> over = await repo.getObjectsOverCapacity(2);
        expect(over.map((CacheObject o) => o.key), <String>[_key(0), _key(1)]);
        expect(indexedKeys(repo), <String>{
          _key(2),
          _key(3),
        }, reason: 'what the store keeps stays indexed');

        // The store deletes what it was handed; nothing may come back.
        final Set<CacheObject> handed = <CacheObject>{...old, ...over};
        expect(handed, hasLength(2), reason: 'the stale one is in both lists');
        expect(await repo.deleteAll(handed.map((CacheObject o) => o.id!)), 2);
        for (final CacheObject o in handed) {
          expect(await repo.get(o.key), isNull);
        }
        expect(indexedKeys(repo), <String>{_key(2), _key(3)});
        expect((await repo.get(_key(2)))?.id, stored[_key(2)]!.id);
      },
    );

    test('an object handed to the cleanup is found again until deleted', () async {
      final JsonCacheInfoRepository repo = await openStore('gap');
      final CacheObject a = await repo.insert(
        _obj(_key(1)),
        setTouchedToNow: false,
      );
      final List<CacheObject> doomed = await repo.getObjectsOverCapacity(0);
      expect(doomed.single.id, a.id);
      expect(indexedKeys(repo), isEmpty);

      // The store has not deleted it yet: the base still holds it, so must we.
      expect((await repo.get(_key(1)))?.id, a.id);
      expect(indexedKeys(repo), <String>{_key(1)}, reason: 'found, re-added');

      await repo.deleteAll(<int>[a.id!]);
      expect(await repo.get(_key(1)), isNull);
      expect(indexedKeys(repo), isEmpty);
    });
  });

  group('races', () {
    test('a delete landing while an insert persists is not undone', () async {
      final JsonCacheInfoRepository repo = await openStore('race_insert');
      final Future<CacheObject> pending = repo.insert(
        _obj(_key(1)),
        setTouchedToNow: false,
      );
      // The base holds the object the moment insert() was called.
      final List<CacheObject> all = await repo.getAllObjects();
      expect(all.single.key, _key(1));
      expect(await repo.deleteAll(<int>[all.single.id!]), 1);

      await pending; // its (late) answer must not resurrect the object
      expect(indexedKeys(repo), isEmpty);
      expect(await repo.get(_key(1)), isNull);
      expect(await repo.getAllObjects(), isEmpty);
    });

    test(
      'a lookup answered after a delete does not re-index the object',
      () async {
        final JsonCacheInfoRepository repo = await openStore('race_lookup');
        final CacheObject a = await repo.insert(
          _obj(_key(1)),
          setTouchedToNow: false,
        );
        await repo.getObjectsOverCapacity(0); // evicts the key from the index
        expect(indexedKeys(repo), isEmpty);

        final Future<CacheObject?> lookup = repo.get(_key(1)); // base: found
        final Future<int> delete = repo.delete(a.id!); // base: gone
        expect(
          (await lookup)?.id,
          a.id,
          reason: 'it was asked while the object existed',
        );
        expect(await delete, 1);

        expect(indexedKeys(repo), isEmpty, reason: 'stale answer not kept');
        expect(await repo.get(_key(1)), isNull);
      },
    );

    test(
      'concurrent inserts are all found; the index heals on lookup',
      () async {
        final JsonCacheInfoRepository repo = await openStore('race_many');
        final List<CacheObject> stored = await Future.wait(
          <Future<CacheObject>>[
            for (int i = 0; i < 6; i++)
              repo.insert(_obj(_key(i)), setTouchedToNow: false),
          ],
        );
        expect(
          indexedKeys(repo)!.length,
          lessThan(6),
          reason: 'overlapping inserts do not index their answers',
        );
        for (int i = 0; i < 6; i++) {
          expect((await repo.get(_key(i)))?.id, stored[i].id);
        }
        expect(indexedKeys(repo), hasLength(6), reason: 'lookups healed it');
      },
    );
  });

  group('on-disk format', () {
    test(
      'the same operations leave the same bytes as the base repository',
      () async {
        final JsonCacheInfoRepository sub = await openStore('bytes_sub');
        final JsonCacheInfoRepository plain = JsonCacheInfoRepository(
          path: '${tmp.path}/bytes_plain.json',
        );
        await plain.open();
        opened.add(plain);

        Future<void> script(JsonCacheInfoRepository r) async {
          final CacheObject a = await r.insert(
            _obj(_key(1), eTag: 'a', minutes: 1),
            setTouchedToNow: false,
          );
          final CacheObject b = await r.insert(
            _obj(_key(2), eTag: 'b', minutes: 2),
            setTouchedToNow: false,
          );
          await r.insert(_obj(_key(3), minutes: 3), setTouchedToNow: false);
          await r.update(
            b.copyWith(eTag: 'b2', relativePath: 'b2.file'),
            setTouchedToNow: false,
          );
          await r.insert(
            _obj(_key(1), eTag: 'a-again', minutes: 4),
            setTouchedToNow: false,
          ); // same key, new id, orphan left behind
          await r.update(
            a.copyWith(eTag: 'orphan-update'),
            setTouchedToNow: false,
          );
          await r.delete(b.id!);
          await r.deleteAll(<int>[9999]);
          await r.insert(_obj(_key(4), minutes: 5), setTouchedToNow: false);
          await r.getObjectsOverCapacity(1);
          await r.getOldObjects(const Duration(days: 365));
          await r.get(_key(4));
          await r.deleteAll(<int>[a.id!, 3]);
        }

        await script(sub);
        await script(plain);
        await sub.close();
        await plain.close();
        expect(
          File('${tmp.path}/bytes_sub.json').readAsStringSync(),
          File('${tmp.path}/bytes_plain.json').readAsStringSync(),
        );
      },
    );
  });

  group('randomised', () {
    test('the index never disagrees with the store', () async {
      final Random rnd = Random(20261009);
      final JsonCacheInfoRepository sub = await openStore('rand_sub');
      final JsonCacheInfoRepository plain = JsonCacheInfoRepository(
        path: '${tmp.path}/rand_plain.json',
      );
      await plain.open();
      opened.add(plain);
      final List<String> keys = <String>[for (int i = 0; i < 12; i++) _key(i)];
      final List<Future<Object?>> pending = <Future<Object?>>[];

      // One logical operation, issued to both repositories in the same order,
      // awaited at once or left running (overlapping persists and answers).
      Future<void> both(Future<Object?> Function(JsonCacheInfoRepository) op) {
        final Future<Object?> s = op(sub);
        final Future<Object?> p = op(plain);
        if (rnd.nextBool()) {
          pending
            ..add(s)
            ..add(p);
          return Future<void>.value();
        }
        return Future.wait(<Future<Object?>>[s, p]);
      }

      Future<void> check(int step) async {
        final Map<String, CacheObject> store = <String, CacheObject>{
          for (final CacheObject o in await sub.getAllObjects()) o.key: o,
        };
        expect(
          store.keys.toSet().containsAll(indexedKeys(sub)!),
          isTrue,
          reason: 'step $step: index holds a key the store dropped',
        );
        for (final String k in keys) {
          expect(
            _fields(await sub.get(k)),
            _fields(store[k]),
            reason: 'step $step: get($k)',
          );
        }
      }

      for (int step = 0; step < 150; step++) {
        final List<CacheObject> live = await plain.getAllObjects();
        CacheObject? pick() =>
            live.isEmpty ? null : live[rnd.nextInt(live.length)];
        final String key = keys[rnd.nextInt(keys.length)];
        final CacheObject fresh = _obj(
          key,
          eTag: 'n$step',
          minutes: step,
          relativePath: 'f$step.file',
        );
        switch (rnd.nextInt(8)) {
          case 0:
            await both(
              (JsonCacheInfoRepository r) =>
                  r.insert(fresh, setTouchedToNow: false),
            );
          case 1:
            final CacheObject? o = pick();
            if (o == null) continue;
            final CacheObject changed = o.copyWith(
              eTag: 'u$step',
              relativePath: 'g$step.file',
            );
            await both(
              (JsonCacheInfoRepository r) =>
                  r.update(changed, setTouchedToNow: false),
            );
          case 2:
            await both((JsonCacheInfoRepository r) => r.updateOrInsert(fresh));
          case 3:
            final CacheObject? o = pick();
            if (o == null) continue;
            final CacheObject changed = o.copyWith(eTag: 'x$step');
            await both(
              (JsonCacheInfoRepository r) => r.updateOrInsert(changed),
            );
          case 4:
            final CacheObject? o = pick();
            await both((JsonCacheInfoRepository r) => r.delete(o?.id ?? 9999));
          case 5:
            final List<int> ids = <int>[
              for (final CacheObject o in live)
                if (rnd.nextInt(4) == 0) o.id!,
              if (rnd.nextBool()) 9999,
            ];
            await both((JsonCacheInfoRepository r) => r.deleteAll(ids));
          case 6:
            // the store's cleanup: ask, then delete what it was handed
            final List<CacheObject> doomed = await plain.getObjectsOverCapacity(
              8,
            );
            await sub.getObjectsOverCapacity(8);
            final List<int> ids = <int>[
              for (final CacheObject o in doomed) o.id!,
            ];
            await both((JsonCacheInfoRepository r) => r.deleteAll(ids));
          case 7:
            await sub.getOldObjects(const Duration(days: 365));
        }
        if (rnd.nextInt(5) == 0) {
          await Future.wait(pending);
          pending.clear();
        }
        await check(step);
      }

      await Future.wait(pending);
      await check(150);
      await sub.close();
      await plain.close();

      // clock-stamped ops differ by milliseconds between the two runs
      List<Map<String, dynamic>> disk(String name) =>
          (jsonDecode(File('${tmp.path}/$name.json').readAsStringSync())
                  as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(
                (Map<String, dynamic> m) =>
                    <String, dynamic>{...m}..remove('touched'),
              )
              .toList();
      expect(disk('rand_sub'), disk('rand_plain'));
    });
  });

  group('seedDiskIndex', () {
    setUpAll(() {
      // HeroImageCacheManager.instance asks path_provider for its folders.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => tmp.path,
          );
    });

    // The seed reads the store's metadata FILE itself (what the awaited
    // inserts below persisted) and opens no connection.
    test('seeds from the store file and leaves the repository alone', () async {
      final JsonCacheInfoRepository repo =
          HeroImageCacheManager.instance.config.repo as JsonCacheInfoRepository;
      await repo.open(); // waits for the store's own connection
      final DateTime now = DateTime.now();
      final CacheObject live = await repo.insert(
        CacheObject(
          _key(1),
          relativePath: 'live.file',
          validTill: now.add(const Duration(days: 9)),
        ),
      );
      await repo.insert(
        CacheObject(
          _key(2),
          relativePath: 'dead.file',
          validTill: now.subtract(const Duration(days: 1)),
        ),
      );
      expect(repo.openConnections, 2);
      final Set<String>? before = indexedKeys(repo);
      expect(before, <String>{_key(1), _key(2)});

      expect(
        await HeroImageCacheManager.seedDiskIndex(),
        1,
        reason: 'only the still-valid key is seeded',
      );
      expect(ImageDiskIndex.instance.contains(_key(1)), isTrue);
      expect(ImageDiskIndex.instance.contains(_key(2)), isFalse);

      expect(indexedKeys(repo), before, reason: 'the seed left the index');
      expect(repo.openConnections, 2, reason: 'and opened no connection');
      expect((await repo.get(_key(1)))?.id, live.id);

      await repo.close();
      expect(repo.openConnections, 1);
      expect(indexedKeys(repo), before, reason: 'the store is still open');
    });
  });

  group('timing (printed, not asserted)', () {
    test('2 000 lookups on a 10 000-object store: base vs indexed', () async {
      const int n = 10000;
      const int lookups = 2000;
      final File file = File('${tmp.path}/big.json');
      file.writeAsStringSync(
        jsonEncode(<Map<String, dynamic>>[
          for (int i = 0; i < n; i++)
            _obj(_key(i), id: i + 1).toMap(setTouchedToNow: false),
        ]),
      );

      final JsonCacheInfoRepository plain = JsonCacheInfoRepository(
        path: file.path,
      );
      final JsonCacheInfoRepository indexed =
          HeroImageCacheManager.debugRepository(file.path);
      final Stopwatch sw = Stopwatch()..start();
      await plain.open();
      final Duration plainOpen = sw.elapsed;
      sw
        ..reset()
        ..start();
      await indexed.open();
      final Duration indexedOpen = sw.elapsed;
      opened
        ..add(plain)
        ..add(indexed);
      expect(indexedKeys(indexed), hasLength(n));

      // spread over the whole store: the base scan costs its position
      final List<String> hits = <String>[
        for (int i = 0; i < lookups; i++) _key((i * 5 + 3) % n),
      ];
      final List<String> misses = <String>[
        for (int i = 0; i < 200; i++) '$_cdn/absent$i.jpeg?w=225',
      ];

      Future<Duration> run(
        JsonCacheInfoRepository r,
        List<String> ks, {
        required bool found,
      }) async {
        final Stopwatch w = Stopwatch()..start();
        for (final String k in ks) {
          final CacheObject? o = await r.get(k);
          if ((o != null) != found) fail('get($k) -> $o');
        }
        return w.elapsed;
      }

      // warm both code paths first (JIT), then measure
      await run(plain, hits.take(100).toList(), found: true);
      await run(indexed, hits.take(100).toList(), found: true);
      final Duration plainHits = await run(plain, hits, found: true);
      final Duration indexedHits = await run(indexed, hits, found: true);
      final Duration plainMisses = await run(plain, misses, found: false);
      final Duration indexedMisses = await run(indexed, misses, found: false);

      for (final String k in hits.take(50)) {
        expect(_fields(await indexed.get(k)), _fields(await plain.get(k)));
      }

      double ms(Duration d) => d.inMicroseconds / 1000;
      debugPrint(
        '[repo-index] open $n objects: base ${ms(plainOpen)} ms, '
        'indexed ${ms(indexedOpen)} ms (includes the index build)',
      );
      debugPrint(
        '[repo-index] $lookups hits: base ${ms(plainHits)} ms, '
        'indexed ${ms(indexedHits)} ms => '
        '${(plainHits.inMicroseconds / max(1, indexedHits.inMicroseconds)).toStringAsFixed(1)}x',
      );
      debugPrint(
        '[repo-index] ${misses.length} misses (fall through to the base scan '
        'by design): base ${ms(plainMisses)} ms, '
        'indexed ${ms(indexedMisses)} ms',
      );
    });
  });
}
