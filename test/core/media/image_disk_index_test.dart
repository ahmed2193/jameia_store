// Locks ImageDiskIndex (lib/src/core/media/image_disk_index.dart), the sync
// "known on disk" set behind the load-source probe:
//   * seed() takes the still-valid keys of the disk-metadata repository once,
//     and survives a failing source;
//   * the key bound starts over instead of growing;
//   * markDownloaded maps a fetched URL to its cacheKey, including the EXIF
//     raw fallback (canonical URL fetched into the variant's key);
//   * the image file service marks a key only once a 200 body completed (or a
//     304 kept the file), never on an error status or a broken body;
//   * the store's own cleanup (capacity, stale period) drops the keys it is
//     about to delete, and the seed opens no repository connection;
//   * seedKeys shares the one run, `seeded` flips when it is done, and
//     HeroImageCacheManager.seedDiskIndex reads the store's metadata file
//     itself (inline when small, on a background isolate when large);
//   * clearCache() forgets what the disk and variant indexes knew.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/media/image_variant_index.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String _cdn = 'https://media.jm3eia.com';

CacheObject _obj(String key, DateTime validTill) =>
    CacheObject(key, relativePath: '$key.file', validTill: validTill);

/// HeroImageCacheManager asks path_provider for its folders: answer [dir].
void _mockPathProvider(Directory dir) => TestDefaultBinaryMessengerBinding
    .instance
    .defaultBinaryMessenger
    .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final DateTime now = DateTime(2026, 10, 9, 12);

  group('seed', () {
    test('adds only keys whose validTill is still ahead, once', () async {
      final ImageDiskIndex index = ImageDiskIndex();
      int calls = 0;
      Future<Iterable<CacheObject>> source() async {
        calls++;
        return <CacheObject>[
          _obj('$_cdn/a.jpeg?w=225', now.add(const Duration(days: 300))),
          _obj('$_cdn/b.jpeg?w=225', now.subtract(const Duration(days: 1))),
          _obj('$_cdn/c.jpeg?w=467', now.add(const Duration(seconds: 1))),
        ];
      }

      expect(await index.seed(source, now: () => now), 2);
      expect(index.contains('$_cdn/a.jpeg?w=225'), isTrue);
      expect(index.contains('$_cdn/b.jpeg?w=225'), isFalse, reason: 'stale');
      expect(index.contains('$_cdn/c.jpeg?w=467'), isTrue);
      // Later calls return the first run; the repository is read once.
      expect(await index.seed(source, now: () => now), 2);
      expect(calls, 1);
    });

    test('walks a large repository in chunks and never throws', () async {
      final ImageDiskIndex index = ImageDiskIndex();
      final List<CacheObject> many = <CacheObject>[
        for (int i = 0; i < 2500; i++)
          _obj('$_cdn/p$i.jpeg', now.add(const Duration(days: 1))),
      ];
      expect(await index.seed(() async => many, now: () => now), 2500);
      expect(index.length, 2500);

      final ImageDiskIndex broken = ImageDiskIndex();
      expect(
        await broken.seed(
          () async => throw StateError('no repo'),
          now: () => now,
        ),
        0,
      );
      expect(broken.length, 0);
      broken.markSeen('$_cdn/x.jpeg');
      expect(
        broken.contains('$_cdn/x.jpeg'),
        isTrue,
        reason: 'the other feeds still work',
      );
    });

    test('seedKeys shares the once-per-process run with seed()', () async {
      final ImageDiskIndex index = ImageDiskIndex();
      expect(await index.seedKeys(() async => <String>['k1', 'k2', '']), 2);
      expect(index.contains('k1'), isTrue);
      expect(
        await index.seed(
          () async => <CacheObject>[
            _obj('k3', now.add(const Duration(days: 1))),
          ],
        ),
        2,
        reason: 'the first run already happened',
      );
      expect(index.contains('k3'), isFalse);
    });

    test('seeded flips once the seed is done, even when it failed', () async {
      for (final Future<Iterable<String>> Function() source
          in <Future<Iterable<String>> Function()>[
            () async => <String>['a'],
            () async => throw StateError('no file'),
          ]) {
        final ImageDiskIndex index = ImageDiskIndex();
        int calls = 0;
        index.seeded.addListener(() => calls++);
        expect(index.seeded.value, isFalse);
        final Future<int> run = index.seedKeys(source);
        expect(index.seeded.value, isFalse, reason: 'not before it is done');
        await run;
        expect(index.seeded.value, isTrue);
        expect(calls, 1);
        index.reset();
        expect(index.seeded.value, isFalse, reason: 'reset starts over');
      }
    });
  });

  test('bounded: past maxKeys it starts over', () {
    expect(
      ImageDiskIndex().maxKeys,
      12500,
      reason: "the store's 10 000 files plus headroom",
    );
    final ImageDiskIndex index = ImageDiskIndex(maxKeys: 3);
    for (final String k in <String>['a', 'b', 'c']) {
      index.markSeen(k);
    }
    expect(index.length, 3);
    index.markSeen('b'); // already known: no overflow
    expect(index.length, 3);
    index.markSeen('d');
    expect(index.length, 1);
    expect(index.contains('d'), isTrue);
    expect(index.contains('a'), isFalse);
    index.markSeen('');
    expect(index.length, 1, reason: 'an empty key is ignored');
  });

  group('markDownloaded', () {
    test('url == key: the URL itself is the key', () {
      final ImageDiskIndex index = ImageDiskIndex();
      const String key = '$_cdn/a.jpeg?w=225&h=225&fit=cover&format=webp';
      index.expectDownload(key, key); // a no-op
      index.markDownloaded(key);
      expect(index.contains(key), isTrue);
    });

    test('raw fallback: the canonical URL lands in the variant keys', () {
      final ImageDiskIndex index = ImageDiskIndex();
      const String raw = '$_cdn/exif.jpeg';
      const String small = '$raw?w=225&h=225&fit=cover&format=webp';
      const String big = '$raw?w=467&h=467&fit=cover&format=webp';
      index.expectDownload(raw, small);
      index.expectDownload(raw, big);
      index.markDownloaded(raw);
      expect(index.contains(small), isTrue);
      expect(index.contains(big), isTrue);
      expect(
        index.contains(raw),
        isFalse,
        reason: 'no tile keys the raw bytes under the raw URL',
      );
      // The mapping is consumed: a later plain download of the raw URL (a
      // tile that resolved to the raw URL as its key) marks the URL.
      index.markDownloaded(raw);
      expect(index.contains(raw), isTrue);
    });

    test('remove and clear forget keys', () {
      final ImageDiskIndex index = ImageDiskIndex();
      index.markDownloaded('k1');
      index.markDownloaded('k2');
      index.remove('k1');
      expect(index.contains('k1'), isFalse);
      expect(index.contains('k2'), isTrue);
      index.expectDownload('u', 'k3');
      index.clear();
      expect(index.length, 0);
      index.markDownloaded('u');
      expect(index.contains('k3'), isFalse, reason: 'mapping cleared too');
    });
  });

  group('image file service', () {
    setUp(ImageDiskIndex.instance.reset);
    tearDown(ImageDiskIndex.instance.reset);

    Future<void> fetch(FileService service, String url) async {
      final FileServiceResponse r = await service.get(url);
      try {
        await r.content.drain<void>();
      } catch (_) {
        // a broken body is part of the test
      }
    }

    test('marks after a 200 body completes, or on a 304', () async {
      const String ok = '$_cdn/ok.jpeg?w=225';
      const String same = '$_cdn/same.jpeg?w=225';
      final FileService service = HeroImageCacheManager.debugFileService(
        MockClient((http.Request req) async {
          final bool notModified = req.url.toString() == same;
          return http.Response(
            notModified ? '' : 'bytes',
            notModified ? 304 : 200,
          );
        }),
      );

      final FileServiceResponse r = await service.get(ok);
      expect(
        ImageDiskIndex.instance.contains(ok),
        isFalse,
        reason: 'headers alone are not a file on disk',
      );
      await r.content.drain<void>();
      expect(ImageDiskIndex.instance.contains(ok), isTrue);

      await service.get(same); // 304: nothing to stream, the file is kept
      expect(ImageDiskIndex.instance.contains(same), isTrue);
    });

    test('raw fallback download marks the variant key', () async {
      const String raw = '$_cdn/exif2.jpeg';
      const String key = '$raw?w=225&h=225&fit=cover&format=webp';
      ImageDiskIndex.instance.expectDownload(raw, key);
      await fetch(
        HeroImageCacheManager.debugFileService(
          MockClient((_) async => http.Response('bytes', 200)),
        ),
        raw,
      );
      expect(ImageDiskIndex.instance.contains(key), isTrue);
      expect(ImageDiskIndex.instance.contains(raw), isFalse);
    });

    test('an error status or a broken body marks nothing', () async {
      const String missing = '$_cdn/missing.jpeg?w=225';
      const String cut = '$_cdn/cut.jpeg?w=225';
      final FileService service = HeroImageCacheManager.debugFileService(
        MockClient.streaming((http.BaseRequest req, _) async {
          if (req.url.toString() == missing) {
            return http.StreamedResponse(const Stream<List<int>>.empty(), 404);
          }
          final StreamController<List<int>> body =
              StreamController<List<int>>();
          body
            ..add(<int>[1, 2, 3])
            ..addError(http.ClientException('Connection closed'))
            ..close();
          return http.StreamedResponse(body.stream, 200);
        }),
      );
      await fetch(service, missing);
      await fetch(service, cut);
      expect(ImageDiskIndex.instance.contains(missing), isFalse);
      expect(ImageDiskIndex.instance.contains(cut), isFalse);
    });
  });

  group('store repository', () {
    late Directory tmp;
    setUpAll(() {
      tmp = Directory.systemTemp.createTempSync('hero_img_disk_repo_test');
      _mockPathProvider(tmp);
    });
    setUp(ImageDiskIndex.instance.reset);
    tearDown(ImageDiskIndex.instance.reset);

    test('what the store cleanup is handed leaves the index', () async {
      final JsonCacheInfoRepository repo =
          HeroImageCacheManager.debugRepository('${tmp.path}/cleanup.json');
      await repo.open();
      final DateTime t = DateTime.now();
      const String stale = '$_cdn/stale.jpeg?w=225';
      const String lru = '$_cdn/lru.jpeg?w=225';
      const String fresh = '$_cdn/fresh.jpeg?w=225';
      for (final (String key, Duration age) in <(String, Duration)>[
        (stale, const Duration(days: 400)),
        (lru, const Duration(days: 10)),
        (fresh, const Duration(minutes: 1)),
      ]) {
        await repo.insert(
          CacheObject(
            key,
            relativePath: '${key.hashCode}.file',
            validTill: t.add(const Duration(days: 300)),
            touched: t.subtract(age),
          ),
          setTouchedToNow: false,
        );
        ImageDiskIndex.instance.markSeen(key);
      }

      // CacheStore._cleanupCache deletes exactly what these two return.
      final List<CacheObject> old = await repo.getOldObjects(
        const Duration(days: 365),
      );
      expect(old.map((CacheObject o) => o.key), <String>[stale]);
      expect(ImageDiskIndex.instance.contains(stale), isFalse);
      expect(ImageDiskIndex.instance.contains(lru), isTrue);

      final List<CacheObject> over = await repo.getObjectsOverCapacity(1);
      expect(over.map((CacheObject o) => o.key), <String>[
        stale,
        lru,
      ], reason: 'least recently touched first');
      expect(ImageDiskIndex.instance.contains(lru), isFalse);
      expect(
        ImageDiskIndex.instance.contains(fresh),
        isTrue,
        reason: 'what the store keeps stays known',
      );
      await repo.close();
    });

    test('the image store uses it; the seed opens no connection', () async {
      final CacheInfoRepository repo =
          HeroImageCacheManager.instance.config.repo;
      expect(
        repo.runtimeType,
        HeroImageCacheManager.debugRepository('${tmp.path}/x.json').runtimeType,
      );
      expect(await HeroImageCacheManager.seedDiskIndex(), 0);
      expect(
        (repo as JsonCacheInfoRepository).openConnections,
        1,
        reason: "only the store's own connection is left open",
      );
    });

    test('clearCache forgets the disk and the variant index', () async {
      const String key = '$_cdn/gone.jpeg?w=225&h=225&fit=cover&format=webp';
      ImageDiskIndex.instance.markSeen(key);
      final ImageVariant v = ImageVariant.of(
        '$_cdn/gone.jpeg',
        wireW: 225,
        wireH: 225,
        fit: 'cover',
        format: 'webp',
      );
      ImageVariantIndex.instance.record(v.assetId, v);

      await HeroImageCacheManager.clearCache();

      expect(ImageDiskIndex.instance.contains(key), isFalse);
      expect(ImageVariantIndex.instance.variantsOf(v.assetId), isEmpty);
    });
  });

  group('metadata-file seed', () {
    late Directory tmp;
    late File file;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    /// One repository entry exactly as `JsonCacheInfoRepository` writes it.
    Map<String, dynamic> entry(int id, String key, {required bool valid}) =>
        CacheObject(
          key,
          id: id,
          relativePath: '$id.file',
          validTill: DateTime.fromMillisecondsSinceEpoch(
            nowMs + (valid ? 1 : -1) * 86400000,
          ),
          touched: DateTime.fromMillisecondsSinceEpoch(nowMs),
        ).toMap(setTouchedToNow: false);

    setUpAll(() {
      tmp = Directory.systemTemp.createTempSync('hero_img_seed_file_test');
      // The file JsonCacheInfoRepository(databaseName: 'heroAppImageCache')
      // keeps in the application-support folder.
      file = File('${tmp.path}${Platform.pathSeparator}heroAppImageCache.json');
      _mockPathProvider(tmp);
    });
    setUp(ImageDiskIndex.instance.reset);
    tearDown(() {
      ImageDiskIndex.instance.reset();
      if (file.existsSync()) file.deleteSync();
    });

    test('no file: nothing to seed, and seeded still flips', () async {
      expect(await HeroImageCacheManager.seedDiskIndex(), 0);
      expect(ImageDiskIndex.instance.seeded.value, isTrue);
    });

    test('a small file is read inline: still-valid keys only', () async {
      file.writeAsStringSync(
        jsonEncode(<Map<String, dynamic>>[
          entry(1, '$_cdn/a.jpeg?w=225', valid: true),
          entry(2, '$_cdn/b.jpeg?w=225', valid: false),
        ]),
      );
      expect(file.lengthSync(), lessThan(50 * 1024));
      expect(await HeroImageCacheManager.seedDiskIndex(), 1);
      expect(ImageDiskIndex.instance.contains('$_cdn/a.jpeg?w=225'), isTrue);
      expect(ImageDiskIndex.instance.contains('$_cdn/b.jpeg?w=225'), isFalse);
    });

    test('a large file is parsed off the UI isolate, same answer', () async {
      const int n = 3000;
      file.writeAsStringSync(
        jsonEncode(<Map<String, dynamic>>[
          for (int i = 0; i < n; i++)
            entry(
              i + 1,
              '$_cdn/2026/p$i.jpeg?w=225&h=216&fit=cover&format=webp',
              valid: i % 10 != 0,
            ),
        ]),
      );
      expect(
        file.lengthSync(),
        greaterThan(50 * 1024),
        reason: 'takes the Isolate.run path',
      );
      expect(await HeroImageCacheManager.seedDiskIndex(), n - n ~/ 10);
      expect(ImageDiskIndex.instance.seeded.value, isTrue);
      expect(
        ImageDiskIndex.instance.contains(
          '$_cdn/2026/p1.jpeg?w=225&h=216&fit=cover&format=webp',
        ),
        isTrue,
      );
      expect(
        ImageDiskIndex.instance.contains(
          '$_cdn/2026/p0.jpeg?w=225&h=216&fit=cover&format=webp',
        ),
        isFalse,
        reason: 'expired',
      );
    });

    test('validKeysInJson: malformed input reads as empty or is skipped', () {
      expect(HeroImageCacheManager.validKeysInJson('not json', nowMs), isEmpty);
      expect(HeroImageCacheManager.validKeysInJson('{"a": 1}', nowMs), isEmpty);
      final String mixed = jsonEncode(<Object>[
        'nope',
        <String, dynamic>{'url': 'no id'},
        entry(7, '$_cdn/ok.jpeg', valid: true),
      ]);
      expect(HeroImageCacheManager.validKeysInJson(mixed, nowMs), <String>[
        '$_cdn/ok.jpeg',
      ]);
    });
  });
}
