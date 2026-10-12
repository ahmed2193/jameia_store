// Locks the debug-only image-load trace (lib/src/core/media/image_load_trace.dart):
//   * counters, the process-lifetime "seen" tagging, rebuild dedupe and the
//     per-asset variant budget, with fake keys and no network;
//   * memory / fade detection read the EXACT RAM key the package uses
//     (ResizeImage(CachedNetworkImageProvider(cacheKey), memW, memH));
//   * a disabled trace records nothing; ImageBytesTracker turns it on;
//   * the lines go to the VM log under `IMGCACHE` in the reference's format
//     (`[IMGCACHE] build src=…`, `[IMGCACHE] SUMMARY …`), captured here
//     through MediaLog.debugSink.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_bytes_tracker.dart';
import 'package:hero_mart/src/core/media/image_load_trace.dart';
import 'package:hero_mart/src/core/media/image_prefetch_token.dart';
import 'package:hero_mart/src/core/media/media_log.dart';

const String _cdn = 'https://media.jm3eia.com';
const Duration _fade = Duration(milliseconds: 280);
const Duration _day = Duration(days: 1);

/// Puts a completed image into the ImageCache under [key] (keepAlive).
void _seed(Object key, ui.Image image) {
  PaintingBinding.instance.imageCache.putIfAbsent(
    key,
    () => OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
    ),
  );
}

Map<String, Object> get _s => ImageLoadTrace.snapshot();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final List<String> logs = <String>[];

  setUpAll(() {
    // Fake disk: keys containing "disk" are fresh on disk, "stale" are
    // expired on disk, anything else is not cached (network).
    ImageLoadTrace.diskHint = (String k) => k.contains('disk');
    ImageLoadTrace.diskLookup = (String k) async {
      if (k.contains('stale')) return DateTime(2000);
      return k.contains('disk') ? DateTime.now().add(_day) : null;
    };
  });

  setUp(() {
    logs.clear();
    MediaLog.debugSink = (String name, String m) =>
        logs.add(MediaLog.format(name, m));
    ImageLoadTrace.enabled = true;
    ImageLoadTrace.reset();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  tearDown(() {
    ImageLoadTrace.enabled = false;
    ImageBytesTracker.enabled = false;
    MediaLog.debugSink = null;
  });

  test('mounts, seen tagging, rebuild dedupe and the variant budget', () async {
    const String base = '$_cdn/t1/a.jpeg';
    final Object a = Object();
    ImageLoadTrace.onBuild(a, '$base?w=200', '$base?w=200', 200, 200, 100, 100);
    ImageLoadTrace.onBuild(a, '$base?w=200', '$base?w=200', 200, 200, 100, 100);
    ImageLoadTrace.onBuild(
      Object(),
      '$base?w=400',
      '$base?w=400',
      400,
      400,
      200,
      200,
    );
    ImageLoadTrace.onBuild(
      Object(),
      '$base?w=600',
      '$base?w=600',
      600,
      600,
      300,
      300,
    );
    await pumpEventQueue();

    expect(_s['mounts'], 3);
    expect(_s['rebuilds'], 1, reason: 'same element + same key = rebuild');
    expect(_s['seen.mounts'], 2, reason: 'first build of the asset is unseen');
    expect(_s['net'], 3);
    expect(_s['seen.net'], 2);
    expect(_s['assets'], 1);
    expect(_s['variantsOver2'], 1);
    final String line = ImageLoadTrace.summary();
    expect(line, startsWith('[IMGCACHE] SUMMARY mounts=3 mem=0 disk=0 net=3'));
    expect(line, contains('| seen: mounts=2 mem=0 disk=0 net=2'));
    expect(line, contains('variants>2=1'));
    expect(logs, contains(line), reason: 'the same line went to the VM log');
    expect(
      logs.where((String l) => l.startsWith('[IMGCACHE] build src=network?')),
      hasLength(3),
    );
    expect(
      logs,
      contains('[IMGCACHE] resolve key=$base?w=200 src=network'),
      reason: 'the reference line format',
    );

    // reset() clears the scenario but "seen" lives for the process.
    ImageLoadTrace.reset();
    expect(logs.last, '[IMGCACHE] RESET');
    ImageLoadTrace.onBuild(
      Object(),
      '$base?w=800',
      '$base?w=800',
      800,
      800,
      400,
      400,
    );
    await pumpEventQueue();
    expect(_s['mounts'], 1);
    expect(_s['seen.mounts'], 1);
    expect(_s['variantsOver2'], 0);
  });

  test('disk and stale hits resolve asynchronously', () async {
    const String fresh = '$_cdn/t2/disk.jpeg?w=100';
    const String stale = '$_cdn/t2/stale.jpeg?w=100';
    ImageLoadTrace.onBuild(Object(), fresh, fresh, 100, 100, 50, 50);
    ImageLoadTrace.onBuild(Object(), stale, stale, 100, 100, 50, 50);
    await pumpEventQueue();
    expect(_s['disk'], 2);
    expect(_s['stale'], 1);
    expect(_s['net'], isNull);
    expect(logs, contains('[IMGCACHE] resolve key=$stale src=disk-stale'));
  });

  test('memory hit and fade read the exact ResizeImage RAM key', () async {
    final ui.Image img = await createTestImage(width: 2, height: 2);
    addTearDown(img.dispose);
    const String key = '$_cdn/t3/m.jpeg?w=200&h=160&fit=cover&format=webp';
    final Object ramKey = ImageLoadTrace.memoryKey(key, 200, 160);
    expect(ramKey, isA<ResizeImageKey>());
    expect(ramKey, ImageLoadTrace.memoryKey(key, 200, 160));
    expect(ramKey == ImageLoadTrace.memoryKey(key, 400, 320), isFalse);
    _seed(ramKey, img);

    ImageLoadTrace.onBuild(Object(), key, key, 200, 160, 100, 80);
    // Same asset, other decode size: a different RAM entry.
    ImageLoadTrace.onBuild(Object(), key, key, 400, 320, 200, 160);
    await pumpEventQueue();
    expect(_s['mem'], 1);
    expect(_s['net'], 1);

    // Placeholder shown while loading; landing build (key complete) = fade.
    const String k2 = '$_cdn/t3/f.jpeg?w=200&h=160&fit=cover&format=webp';
    final Object site = Object();
    ImageLoadTrace.onPlaceholder(site, k2, 200, 160, 0, _fade);
    expect(_s['shimmer'], 1);
    expect(_s['fade'], isNull);
    _seed(ImageLoadTrace.memoryKey(k2, 200, 160), img);
    ImageLoadTrace.onPlaceholder(site, k2, 200, 160, 0, _fade);
    ImageLoadTrace.onPlaceholder(site, k2, 200, 160, 0, _fade);
    expect(_s['shimmer'], 1);
    expect(_s['fade'], 1);
    // A retry (new attempt) re-shows the placeholder.
    ImageLoadTrace.onPlaceholder(site, k2, 200, 160, 1, _fade);
    expect(_s['shimmer_retry'], 1);
    // No fade is counted when fadeInDuration is zero.
    ImageLoadTrace.onPlaceholder(Object(), k2, 200, 160, 0, Duration.zero);
    expect(_s['fade'], 2, reason: 'attempt 1 above landed; zero-fade did not');
    // A disk-policy placeholder is a still box, not a shimmer.
    ImageLoadTrace.onPlaceholder(
      Object(),
      k2,
      200,
      160,
      0,
      Duration.zero,
      policy: 'disk',
    );
    expect(_s['placeholder_disk'], 1);
    expect(_s['shimmer'], 2);
  });

  test('fail is counted once per attempt with the HTTP status', () {
    final Object site = Object();
    const String k = '$_cdn/t4/x.jpeg?w=50';
    ImageLoadTrace.onFail(site, k, 0, const HttpExceptionWithStatus(404, 'x'));
    ImageLoadTrace.onFail(site, k, 0, const HttpExceptionWithStatus(404, 'x'));
    ImageLoadTrace.onFail(site, k, 1, Exception('timeout'));
    expect(_s['fail'], 2);
    expect(logs, contains('[IMGCACHE] fail key=$k status=404 attempt=0'));
    expect(logs, contains('[IMGCACHE] fail key=$k status=none attempt=1'));
  });

  test('net GET counts every request per URL and flags duplicates', () {
    ImageLoadTrace.onNetworkGet('$_cdn/t5/a.jpeg?w=1');
    ImageLoadTrace.onNetworkGet('$_cdn/t5/a.jpeg?w=1');
    ImageLoadTrace.onNetworkGet('$_cdn/t5/b.jpeg?w=1');
    expect(_s['get'], 3);
    expect((_s['getsByUrl']! as Map<String, int>)['$_cdn/t5/a.jpeg?w=1'], 2);
    expect(ImageLoadTrace.summary(), contains('get=3 dupGET=1'));
    expect(logs, contains('[IMGCACHE] net GET $_cdn/t5/a.jpeg?w=1 n=2'));
  });

  test('redecide moves the policy and the first-attempt shimmer count', () {
    const String k = '$_cdn/t8/seed.jpeg?w=225';
    final Object site = Object();
    ImageLoadTrace.onBuild(site, k, k, 225, 225, 100, 100, policy: 'network');
    ImageLoadTrace.onPlaceholder(site, k, 225, 225, 0, _fade);
    expect(_s['policy.network'], 1);
    expect(_s['shimmer'], 1);
    ImageLoadTrace.onRedecide(site, k, from: 'network', to: 'disk');
    expect(_s['policy.network'], 0);
    expect(_s['policy.disk'], 1);
    expect(_s['shimmer'], 0);
    expect(_s['placeholder_disk'], 1);
    expect(_s['redecide'], 1);
    expect(
      logs,
      contains(
        '[IMGCACHE] redecide key=$k seen=0 policy=disk from=network cause=seed',
      ),
    );
  });

  test('a disabled trace records nothing; ImageBytesTracker enables it', () {
    ImageLoadTrace.enabled = false;
    logs.clear();
    expect(ImageLoadTrace.enabled, isFalse);
    const String k = '$_cdn/t6/off.jpeg?w=1';
    final Object site = Object();
    ImageLoadTrace.onBuild(Object(), k, k, 1, 1, 1, 1);
    ImageLoadTrace.onPlaceholder(site, k, 1, 1, 0, _fade);
    ImageLoadTrace.onFail(site, k, 0, null);
    ImageLoadTrace.onNetworkGet(k);
    ImageLoadTrace.logVm('HomeCubit', 'create');
    expect(_s.values.whereType<int>().every((int v) => v == 0), isTrue);
    expect(_s['getsByUrl'], isEmpty);
    expect(logs, isEmpty);

    ImageBytesTracker.enabled = true;
    expect(ImageLoadTrace.enabled, isTrue);
    ImageLoadTrace.logVm('HomeCubit', 'create');
    expect(logs, <String>['[VMLIFE] HomeCubit create']);
  });

  test('the prefetch summary keeps the reference line format', () {
    const PrefetchResult r = (
      queued: 8,
      skippedDisk: 1,
      skippedOffline: 0,
      done: 2,
      cancelled: 6,
      failed: 0,
    );
    expect(
      MediaLog.format(MediaLog.trace, prefetchSummary(r)),
      '[IMGCACHE] prefetch queued=8 skipped_disk=1 skipped_offline=0 done=2 '
      'cancelled=6 failed=0',
    );
  });

  test('imageCacheStats reports the live ImageCache', () {
    final String line = ImageLoadTrace.imageCacheStats();
    expect(line, startsWith('[IMGCACHE] IMAGECACHE size=0/'));
    expect(logs, contains(line));
  });
}
