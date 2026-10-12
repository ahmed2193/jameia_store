// The disk prefetcher (lib/src/core/media/image_prefetcher.dart): bounded
// concurrency, dedupe (within and across calls), disk-known skip (up front
// and again right before the GET; no getFileFromCache probe), offline skip,
// cancellation, swallowed failures and their negative cache, the quiet-UI
// start gate (after the calling frame, behind animations, ONE shared wait per
// batch capped by maxDefer, polls stop on cancel, held by a screen's image
// GETs but not by the prefetch's own), the 15 s body-idle stall, and
// HeroImageCacheManager.preCacheImages delegating to it.
// Hand-rolled fakes only (no mocktail in this repo).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/media/image_prefetch_gate.dart';
import 'package:hero_mart/src/core/media/image_prefetcher.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Nothing reads the returned file.
class _FakeFileInfo extends Fake implements FileInfo {}

FileInfo _info(String url) => _FakeFileInfo();

/// Records cache reads (the prefetcher must make none); downloads run
/// [onDownload] first, then complete at once, fail for [failing], or wait
/// for [release] while [hold] is set.
class _FakeManager extends Fake implements BaseCacheManager {
  final Set<String> failing = <String>{};
  Object failure = const HttpExceptionWithStatus(404, 'x');
  final List<String> cacheReads = <String>[];
  final List<String> downloads = <String>[];
  final Map<String, Completer<FileInfo>> pending =
      <String, Completer<FileInfo>>{};
  Future<void> Function(String url)? onDownload;
  bool hold = false;
  int inFlight = 0, maxInFlight = 0;

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    cacheReads.add(key);
    return null;
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    downloads.add(url);
    inFlight++;
    maxInFlight = math.max(maxInFlight, inFlight);
    try {
      await onDownload?.call(url);
      if (failing.contains(url)) throw failure;
      if (!hold) return _info(url);
      return await (pending[url] = Completer<FileInfo>()).future;
    } finally {
      inFlight--;
    }
  }

  void release(String url) => pending.remove(url)!.complete(_info(url));
}

/// No start gate (a zero budget skips it).
const QuietUiGate _noGate = QuietUiGate(maxDefer: Duration.zero);

ImagePrefetcher _prefetcher(
  _FakeManager m, {
  bool Function(String)? known,
  PrefetchFailures? failures,
}) => ImagePrefetcher(
  manager: () => m,
  isKnownOnDisk: known ?? (_) => false,
  gate: _noGate,
  failures: failures,
);

/// A perpetual animation (an ambient loop): transient callbacks every frame.
const Widget _perpetualTicker = Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: CircularProgressIndicator()),
);

Future<void> _settle() async {
  for (int i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ImageDiskIndex.instance.reset();
    ImageNetActivity.debugReset();
  });
  tearDown(() => HeroImageCacheManager.debugLoaderOverride = null);

  test('never more than `concurrency` (2) downloads in flight', () async {
    final _FakeManager m = _FakeManager()..hold = true;
    final Future<PrefetchResult> done = _prefetcher(m).prefetch(<String>[
      'u1',
      'u2',
      'u3',
      'u4',
      'u5',
      'u6',
    ], token: PrefetchToken());
    await _settle();
    expect(m.inFlight, 2);
    while (m.pending.isNotEmpty) {
      m.release(m.pending.keys.first);
      await _settle();
      expect(m.inFlight, lessThanOrEqualTo(2));
    }
    final PrefetchResult r = await done;
    expect(m.maxInFlight, 2);
    expect(m.downloads, hasLength(6));
    expect(r.done, 6);
  });

  test('the pool is capped at maxConcurrency (3) whatever is asked', () async {
    final _FakeManager m = _FakeManager()..hold = true;
    final Future<PrefetchResult> done = _prefetcher(m).prefetch(
      <String>['a', 'b', 'c', 'd', 'e'],
      token: PrefetchToken(),
      concurrency: 8,
    );
    await _settle();
    expect(m.inFlight, ImagePrefetcher.maxConcurrency);
    while (m.pending.isNotEmpty) {
      m.release(m.pending.keys.first);
      await _settle();
    }
    await done;
    expect(m.maxInFlight, 3);
  });

  test(
    'dedupes within a call and joins a job queued by another call',
    () async {
      final _FakeManager m = _FakeManager()..hold = true;
      final ImagePrefetcher p = _prefetcher(m);
      final Future<PrefetchResult> a = p.prefetch(<String>[
        'a',
        'a',
        '',
        'b',
      ], token: PrefetchToken());
      final Future<PrefetchResult> b = p.prefetch(<String>[
        'b',
        'c',
      ], token: PrefetchToken());
      await _settle();
      while (m.pending.isNotEmpty) {
        m.release(m.pending.keys.first);
        await _settle();
      }
      final PrefetchResult ra = await a, rb = await b;
      expect(m.downloads, <String>['a', 'b', 'c']);
      expect(ra.queued, 2);
      expect(rb.queued, 2);
      expect(ra.done + rb.done, 4); // 'b' counts for both callers
    },
  );

  test(
    'disk-known is skipped untouched; the rest never probe the cache',
    () async {
      final PrefetchResult r = await _prefetcher(
        _FakeManager(),
        known: (String u) => u == 'known',
      ).prefetch(<String>['known', 'miss'], token: PrefetchToken());
      expect(r.skippedDisk, 1);
      expect(r.done, 1);
      final _FakeManager m = _FakeManager();
      await _prefetcher(m).prefetch(<String>['a', 'b'], token: PrefetchToken());
      // Index-unknown = not on disk; a file there anyway is a conditional GET
      // (304) inside downloadFile, which the file service marks.
      expect(m.cacheReads, isEmpty);
      expect(m.downloads, <String>['a', 'b']);
    },
  );

  test('a URL that lands on disk while queued is not downloaded', () async {
    final Set<String> known = <String>{};
    final _FakeManager m = _FakeManager()..hold = true;
    final Future<PrefetchResult> done = _prefetcher(
      m,
      known: known.contains,
    ).prefetch(<String>['a', 'b'], token: PrefetchToken(), concurrency: 1);
    await _settle();
    expect(m.downloads, <String>['a']);
    known.add('b'); // a visible tile fetched it meanwhile
    m.release('a');
    final PrefetchResult r = await done;
    expect(m.downloads, <String>['a']);
    expect(r.skippedDisk, 1);
    expect(r.done, 1);
  });

  test('the default disk probe reads ImageDiskIndex', () async {
    final _FakeManager m = _FakeManager();
    HeroImageCacheManager.debugLoaderOverride = m;
    ImageDiskIndex.instance.markSeen('seen');
    final ImagePrefetcher p = ImagePrefetcher(gate: _noGate);
    final PrefetchResult r = await p.prefetch(<String>[
      'seen',
      'new',
    ], token: PrefetchToken());
    expect(m.downloads, <String>['new']);
    expect(r.skippedDisk, 1);
    expect(r.done, 1);
  });

  test('offline: nothing is read or downloaded', () async {
    final _FakeManager m = _FakeManager();
    final PrefetchResult r = await _prefetcher(m).prefetch(
      <String>['a', 'b'],
      token: PrefetchToken(),
      isOnline: () => false,
    );
    expect(m.cacheReads, isEmpty);
    expect(m.downloads, isEmpty);
    expect(r.skippedOffline, 2);
    expect(r.queued, 0);
  });

  test('going offline mid-queue skips the jobs not started yet', () async {
    bool online = true;
    final _FakeManager m = _FakeManager()..hold = true;
    final Future<PrefetchResult> done = _prefetcher(m).prefetch(
      <String>['a', 'b', 'c'],
      token: PrefetchToken(),
      concurrency: 1,
      isOnline: () => online,
    );
    await _settle();
    expect(m.downloads, <String>['a']);
    online = false;
    m.release('a');
    final PrefetchResult r = await done;
    expect(m.downloads, <String>['a']);
    expect(r.done, 1);
    expect(r.skippedOffline, 2);
  });

  test('cancel drops the queued jobs; the in-flight one finishes', () async {
    final _FakeManager m = _FakeManager()..hold = true;
    final PrefetchToken token = PrefetchToken();
    final Future<PrefetchResult> done = _prefetcher(m)
        .prefetch(<String>['a', 'b', 'c', 'd'], token: token, concurrency: 1);
    await _settle();
    expect(m.downloads, <String>['a']);
    token.cancel();
    m.release('a');
    final PrefetchResult r = await done;
    expect(m.downloads, <String>['a']); // b, c, d never went out
    expect(r.done, 1);
    expect(r.cancelled, 3);
  });

  test('a job another live token shares survives one cancel', () async {
    final _FakeManager m = _FakeManager()..hold = true;
    final ImagePrefetcher p = _prefetcher(m);
    final PrefetchToken t1 = PrefetchToken(), t2 = PrefetchToken();
    final Future<PrefetchResult> a = p.prefetch(
      <String>['x', 'shared'],
      token: t1,
      concurrency: 1,
    );
    final Future<PrefetchResult> b = p.prefetch(
      <String>['shared'],
      token: t2,
      concurrency: 1,
    );
    await _settle();
    t1.cancel();
    m.release('x');
    await _settle();
    m.release('shared');
    final PrefetchResult ra = await a, rb = await b;
    expect(m.downloads, <String>['x', 'shared']);
    expect(rb.done, 1);
    expect(ra.done, 2);
  });

  test('a cancelled token queues nothing', () async {
    final _FakeManager m = _FakeManager();
    final PrefetchResult r = await _prefetcher(m)
        .prefetch(<String>['a'], token: PrefetchToken()..cancel());
    expect(m.cacheReads, isEmpty);
    expect(r.queued, 0);
  });

  test(
    'a failed download is swallowed, not retried, and the rest go on',
    () async {
      final _FakeManager m = _FakeManager()..failing.add('bad');
      final PrefetchResult r = await _prefetcher(m)
          .prefetch(<String>['bad', 'ok'], token: PrefetchToken());
      expect(m.downloads, <String>['bad', 'ok']);
      expect(r.failed, 1);
      expect(r.done, 1);
    },
  );

  test(
    'a failed URL is skipped, counted failed, until failureTtl passes',
    () async {
      DateTime now = DateTime(2026, 10, 9, 12);
      final _FakeManager m = _FakeManager()..failing.add('bad');
      final ImagePrefetcher p = _prefetcher(
        m,
        failures: PrefetchFailures(now: () => now),
      );
      final PrefetchResult first = await p.prefetch(<String>[
        'bad',
        'ok',
      ], token: PrefetchToken());
      expect(first.failed, 1);
      expect(m.downloads, <String>['bad', 'ok']);

      // A repeated warm-up: no new GET for the doomed URL.
      final PrefetchResult again = await p.prefetch(<String>[
        'bad',
      ], token: PrefetchToken());
      expect(again.failed, 1);
      expect(again.queued, 0);
      now = now.add(const Duration(minutes: 9, seconds: 59));
      await p.prefetch(<String>['bad'], token: PrefetchToken());
      expect(m.downloads, <String>['bad', 'ok']);

      now = now.add(const Duration(seconds: 1)); // the 10 min window is over
      final PrefetchResult retried = await p.prefetch(<String>[
        'bad',
      ], token: PrefetchToken());
      expect(m.downloads, <String>['bad', 'ok', 'bad']);
      expect(retried.queued, 1);
      expect(retried.failed, 1);
    },
  );

  test('a stalled body is negative-cached like any other failure', () async {
    final _FakeManager m = _FakeManager()
      ..failing.add('slow')
      ..failure = ImageBodyStalledException('Image body stalled for 15s');
    final ImagePrefetcher p = _prefetcher(m);
    final PrefetchResult first = await p.prefetch(<String>[
      'slow',
    ], token: PrefetchToken());
    expect(first.failed, 1);
    final PrefetchResult again = await p.prefetch(<String>[
      'slow',
    ], token: PrefetchToken());
    expect(again.failed, 1);
    expect(again.queued, 0);
    expect(m.downloads, <String>['slow'], reason: 'no second GET');
  });

  test('a GET that fails because the link dropped is not remembered', () async {
    bool online = true;
    final _FakeManager m = _FakeManager()
      ..failing.add('a')
      ..onDownload = (_) async => online = false;
    final ImagePrefetcher p = _prefetcher(m);
    final PrefetchResult r = await p.prefetch(
      <String>['a'],
      token: PrefetchToken(),
      isOnline: () => online,
    );
    expect(r.skippedOffline, 1);
    expect(r.failed, 0);
    online = true;
    m
      ..onDownload = null
      ..failing.clear();
    final PrefetchResult back = await p.prefetch(
      <String>['a'],
      token: PrefetchToken(),
      isOnline: () => online,
    );
    expect(back.done, 1);
    expect(m.downloads, <String>['a', 'a']);
  });

  group('quiet-UI gate (real SchedulerBinding)', () {
    testWidgets('a prefetch asked for inside a frame starts after it', (
      WidgetTester tester,
    ) async {
      final _FakeManager m = _FakeManager();
      final ImagePrefetcher p = ImagePrefetcher(
        manager: () => m,
        isKnownOnDisk: (_) => false,
      );
      int downloadsDuringFrame = -1;
      tester.binding.addPostFrameCallback((_) {
        p.prefetch(<String>['a'], token: PrefetchToken());
        downloadsDuringFrame = m.downloads.length;
      });
      await tester.pumpWidget(const SizedBox());
      expect(downloadsDuringFrame, 0);
      await tester.pump(const Duration(milliseconds: 10));
      expect(m.downloads, <String>['a']);
      expect(m.cacheReads, isEmpty);
    });

    testWidgets('jobs wait while an animation ticks, then start', (
      WidgetTester tester,
    ) async {
      final _FakeManager m = _FakeManager();
      final ImagePrefetcher p = ImagePrefetcher(
        manager: () => m,
        isKnownOnDisk: (_) => false,
      );
      await tester.pumpWidget(_perpetualTicker);
      p.prefetch(<String>['a'], token: PrefetchToken());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(m.downloads, isEmpty); // 500 ms of animation: nothing started
      await tester.pumpWidget(const SizedBox()); // the animation is gone
      // Its last tick had already asked for a frame; the engine delivers it
      // within a vsync (here: the next pump), then the UI is quiet.
      await tester.pump();
      expect(m.downloads, isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      expect(m.downloads, <String>['a']);
    });

    testWidgets('a perpetual animation delays a job by maxDefer at most', (
      WidgetTester tester,
    ) async {
      final _FakeManager m = _FakeManager();
      final ImagePrefetcher p = ImagePrefetcher(
        manager: () => m,
        isKnownOnDisk: (_) => false,
        gate: const QuietUiGate(maxDefer: Duration(milliseconds: 400)),
      );
      await tester.pumpWidget(_perpetualTicker);
      p.prefetch(<String>['a'], token: PrefetchToken());
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(m.downloads, isEmpty);
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(m.downloads, <String>['a']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      '8 URLs under a perpetual ticker all start within ONE maxDefer',
      (WidgetTester tester) async {
        final _FakeManager m = _FakeManager();
        final ImagePrefetcher p = ImagePrefetcher(
          manager: () => m,
          isKnownOnDisk: (_) => false,
          gate: const QuietUiGate(maxDefer: Duration(milliseconds: 400)),
        );
        await tester.pumpWidget(_perpetualTicker);
        PrefetchResult? r;
        p
            .prefetch(<String>[
              for (int i = 0; i < 8; i++) 'u$i',
            ], token: PrefetchToken())
            .then((PrefetchResult v) => r = v);
        for (int i = 0; i < 7; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(m.downloads, isEmpty);
        for (int i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        // One shared wait, then back to back (2 workers). A gate per job and
        // worker would have needed 4 × 400 ms.
        expect(m.downloads, hasLength(8));
        expect(m.maxInFlight, lessThanOrEqualTo(2));
        expect(r?.done, 8);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('cancel stops the gate polling for jobs nobody wants', (
      WidgetTester tester,
    ) async {
      int polls = 0;
      final _FakeManager m = _FakeManager();
      final ImagePrefetcher p = ImagePrefetcher(
        manager: () => m,
        isKnownOnDisk: (_) => false,
        gate: QuietUiGate(
          networkBusy: () {
            polls++;
            return false;
          },
        ),
      );
      await tester.pumpWidget(_perpetualTicker);
      final PrefetchToken token = PrefetchToken();
      PrefetchResult? r;
      p
          .prefetch(<String>['a', 'b', 'c'], token: token)
          .then((PrefetchResult v) => r = v);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(polls, greaterThan(0));
      token.cancel(); // the screen is covered: a tap elsewhere
      await tester.pump(const Duration(milliseconds: 100));
      final int atCancel = polls;
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(polls, atCancel, reason: 'no poller left for dead jobs');
      expect(m.downloads, isEmpty);
      expect(r?.cancelled, 3);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a screen's image GET holds the gate; the prefetch's own not", (
      WidgetTester tester,
    ) async {
      const String tile = 'https://media.jm3eia.com/t/tile.jpeg';
      const String warm = 'https://media.jm3eia.com/t/warm.jpeg';
      final StreamController<List<int>> tileBody =
          StreamController<List<int>>();
      final FileService service = HeroImageCacheManager.debugFileService(
        MockClient.streaming((http.BaseRequest req, _) async {
          final Stream<List<int>> body = req.url.toString() == tile
              ? tileBody.stream
              : Stream<List<int>>.value(<int>[1, 2, 3]);
          return http.StreamedResponse(body, 200);
        }),
      );

      // A visible tile's GET: counted from the request to the end of its body.
      FileServiceResponse? tileResponse;
      service.get(tile).then((FileServiceResponse r) => tileResponse = r);
      expect(ImageNetActivity.visibleInFlight, 1);
      await tester.pump();
      final StreamSubscription<List<int>> saving = tileResponse!.content.listen(
        null,
      );

      int? countedDuringWarm;
      final _FakeManager m = _FakeManager()
        ..onDownload = (String url) async {
          final Future<FileServiceResponse> get = service.get(url);
          countedDuringWarm = ImageNetActivity.visibleInFlight;
          await (await get).content.drain<void>();
        };
      final ImagePrefetcher p = ImagePrefetcher(
        manager: () => m,
        isKnownOnDisk: (_) => false,
        gate: const QuietUiGate(maxDefer: Duration(seconds: 2)),
      );
      PrefetchResult? r;
      p
          .prefetch(<String>[warm], token: PrefetchToken())
          .then((PrefetchResult v) => r = v);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(m.downloads, isEmpty, reason: 'quiet UI, busy network: wait');

      unawaited(tileBody.close()); // the tile's bytes are in
      await tester.pump();
      expect(ImageNetActivity.visibleInFlight, 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(m.downloads, <String>[warm]);
      expect(countedDuringWarm, 0, reason: "the prefetch's GET is not counted");
      expect(r?.done, 1);
      expect(ImageNetActivity.visibleInFlight, 0);
      unawaited(saving.cancel());
    });

    testWidgets('a body silent for 15 s fails as ImageBodyStalledException', (
      WidgetTester tester,
    ) async {
      const String url = 'https://media.jm3eia.com/t/stalled.jpeg';
      final StreamController<List<int>> body = StreamController<List<int>>();
      final FileService service = HeroImageCacheManager.debugFileService(
        MockClient.streaming(
          (_, _) async => http.StreamedResponse(body.stream, 200),
        ),
      );
      FileServiceResponse? response;
      service.get(url).then((FileServiceResponse r) => response = r);
      await tester.pump();
      Object? error;
      bool done = false;
      response!.content.listen(
        null,
        onError: (Object e) => error = e,
        onDone: () => done = true,
      );
      body.add(<int>[1, 2]);
      await tester.pump(const Duration(seconds: 14));
      body.add(<int>[3]); // a chunk re-arms the idle timer
      await tester.pump(const Duration(seconds: 14));
      expect(error, isNull);
      expect(ImageNetActivity.visibleInFlight, 1);
      await tester.pump(const Duration(seconds: 2)); // 16 s of silence
      // A ClientException (no status) of its own type: the image widget
      // retries the same URL on its backoff, with no raw hop.
      expect(error, isA<ImageBodyStalledException>());
      expect(error, isA<http.ClientException>());
      expect(error.toString(), isNot(contains('statusCode')));
      expect(done, isTrue);
      expect(ImageNetActivity.visibleInFlight, 0);
      expect(ImageDiskIndex.instance.contains(url), isFalse);
      expect(body.hasListener, isFalse, reason: 'the stalled socket is let go');
    });
  });

  testWidgets(
    'preCacheImages delegates: deduped, disk-skipped, no cache probe',
    (WidgetTester tester) async {
      final _FakeManager m = _FakeManager();
      HeroImageCacheManager.debugLoaderOverride = m;
      ImageDiskIndex.instance.markSeen('known');
      bool settled = false;
      HeroImageCacheManager.preCacheImages(<String>['a', 'b', 'a', '', 'known'])
          .then((_) => settled = true);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 10));
      expect(m.cacheReads, isEmpty);
      expect(m.downloads, <String>['a', 'b']);
      expect(settled, isTrue);

      bool offlineSettled = false;
      HeroImageCacheManager.preCacheImages(<String>[
        'c',
      ], isOnline: () => false).then((_) => offlineSettled = true);
      await tester.pump(const Duration(milliseconds: 10));
      expect(m.downloads, <String>[
        'a',
        'b',
      ], reason: 'isOnline passes through');
      expect(offlineSettled, isTrue);
    },
  );
}
