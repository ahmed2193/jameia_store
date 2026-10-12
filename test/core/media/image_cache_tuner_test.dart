// Locks ImageCacheTuner (lib/src/core/media/image_cache_tuner.dart): the RAM
// tier from MemTotal only (low 80 MB/800, mid 160 MB/1500, high 256 MB/2400;
// no MemAvailable step-down), and that memory pressure — through the
// framework's own path into a TrimmingImageCache — trims once per burst,
// never tiers the budget down, and never trims while the app is away.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_cache_tuner.dart';
import 'package:hero_mart/src/core/media/media_log.dart';
import 'package:hero_mart/src/core/media/trimming_image_cache.dart';

/// The test binding with the app's image cache, so the framework's own
/// memory-pressure path (`PaintingBinding.handleMemoryPressure` →
/// `imageCache.clear()`) runs against a [TrimmingImageCache].
class _TrimmingTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ImageCache createImageCache() => TrimmingImageCache(settleDelay: _settle);
}

// Tier "mid" — what install() picks on a non-Android host.
const int _midBytes = 160 << 20;
const int _midCount = 1500;

// A short settle window (the app's is 400 ms) on real time; waits are long
// enough for Windows' ~16 ms timer granularity. Exact window timing is
// locked on the fake clock in trimming_image_cache_test.dart.
const Duration _settle = Duration(milliseconds: 20);
Future<void> _settled() => Future<void>.delayed(_settle * 5);

void main() {
  final _TrimmingTestBinding binding = _TrimmingTestBinding();
  final TrimmingImageCache cache = binding.imageCache as TrimmingImageCache;
  DateTime clock = DateTime(2026, 10, 8, 12);
  cache.now = () => clock;
  late ui.Image image;
  final List<String> logs = <String>[];

  Future<void> send(String channel, ByteData? message) => binding
      .defaultBinaryMessenger
      .handlePlatformMessage(channel, message, (_) {});
  Future<void> pressure() => send(
    SystemChannels.system.name,
    SystemChannels.system.codec.encodeMessage(<String, dynamic>{
      'type': 'memoryPressure',
    }),
  );
  Future<void> lifecycle(AppLifecycleState state) => send(
    SystemChannels.lifecycle.name,
    SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
  );
  void fillTo(int count) {
    for (int i = 0; cache.currentSize < count; i++) {
      cache.putIfAbsent(
        'fill-${clock.millisecondsSinceEpoch}-$i',
        () => OneFrameImageStreamCompleter(
          SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
        ),
      );
    }
  }

  setUpAll(() async {
    // WidgetsBinding.framesEnabled also needs a root widget (what runApp
    // attaches); without one every trim would be deferred as "frames off".
    binding.attachRootWidget(const SizedBox());
    image = await createTestImage(width: 2, height: 2);
    await ImageCacheTuner.install();
  });

  setUp(() {
    logs.clear();
    MediaLog.debugSink = (String name, String m) =>
        logs.add(MediaLog.format(name, m));
  });

  tearDown(() => MediaLog.debugSink = null);

  test('install() applies the RAM tier', () {
    expect(cache.maximumSizeBytes, _midBytes);
    expect(cache.maximumSize, _midCount);
  });

  test('tier table: MemTotal only, unchanged budgets', () {
    ({String name, int bytes, int count}) t(double gb) =>
        ImageCacheTuner.tierFor(gb);
    const ({String name, int bytes, int count}) low = (
      name: 'low',
      bytes: 80 << 20,
      count: 800,
    );
    const ({String name, int bytes, int count}) mid = (
      name: 'mid',
      bytes: 160 << 20,
      count: 1500,
    );
    const ({String name, int bytes, int count}) high = (
      name: 'high',
      bytes: 256 << 20,
      count: 2400,
    );
    expect(t(1.8), low, reason: 'a 2 GB phone (MemTotal ≈ 1.8 GiB)');
    expect(t(2.0), low);
    expect(t(2.4), mid, reason: 'a 2.5 GB emulator');
    expect(t(3.51), mid, reason: 'a 3.5 GiB phone');
    expect(t(4.0), mid);
    expect(t(5.5), high);
    expect(t(-1), mid, reason: 'unknown (non-Android) → mid');
  });

  test('a pressure burst trims once instead of wiping', () async {
    fillTo(1000);
    for (int i = 0; i < 4; i++) {
      await pressure();
    }
    expect(cache.currentSize, 1000, reason: 'decided after the settle window');
    await _settled();

    // A plain ImageCache would be at 0 here; the trim keeps half the budget.
    expect(cache.currentSize, _midCount ~/ 2);
    expect(cache.trimCount, 1);
    expect(cache.maximumSizeBytes, _midBytes);
    expect(cache.maximumSize, _midCount);
    expect(
      logs
          .where(
            (String l) => l.startsWith('[ImageCacheTuner] pressure → trimmed'),
          )
          .single,
      contains('1000→750 entries'),
    );
    expect(
      logs.where(
        (String l) => l.startsWith('[ImageCacheTuner] memory pressure:'),
      ),
      hasLength(4),
    );
  });

  test('repeated pressure never tiers the budget down', () async {
    for (int round = 0; round < 5; round++) {
      clock = clock.add(const Duration(seconds: 31));
      fillTo(1000);
      await pressure();
      await pressure();
      await _settled();
      expect(cache.currentSize, _midCount ~/ 2);
      expect(cache.maximumSizeBytes, _midBytes);
      expect(cache.maximumSize, _midCount);
    }
    expect(logs.any((String l) => l.contains('tier-down')), isFalse);
  });

  test(
    'backgrounding keeps the cache; pressure while away is deferred',
    () async {
      await lifecycle(AppLifecycleState.resumed);
      clock = clock.add(const Duration(seconds: 31));
      fillTo(1000);
      final int before = cache.trimCount;

      // resumed → inactive → hidden → paused: no proactive trim. The
      // scheduler has already turned frames off, so evicted bitmaps would not
      // be released until after resume.
      await lifecycle(AppLifecycleState.paused);
      expect(cache.currentSize, 1000);
      expect(cache.trimCount, before);

      // TRIM_MEMORY_UI_HIDDEN arrives ~4 s later: deferred too.
      clock = clock.add(const Duration(seconds: 4));
      await pressure();
      expect(cache.currentSize, 1000);
      expect(cache.trimCount, before);
      expect(
        logs.where(
          (String l) => l == '[ImageCacheTuner] trim deferred (frames off)',
        ),
        hasLength(1),
      );
      expect(
        logs.any((String l) => l.startsWith('[ImageCacheTuner] paused:')),
        isTrue,
      );

      // Back after a minute: paused → hidden → inactive → resumed does not
      // trim either, even though the rate-limit window has long closed.
      clock = clock.add(const Duration(minutes: 1));
      await lifecycle(AppLifecycleState.resumed);
      expect(cache.currentSize, 1000);
      expect(cache.trimCount, before);
      expect(cache.maximumSizeBytes, _midBytes);
      expect(cache.maximumSize, _midCount);
      expect(
        logs.any((String l) => l.startsWith('[ImageCacheTuner] resumed:')),
        isTrue,
      );

      // With frames running again, the OS's pressure signal is honoured.
      await pressure();
      await _settled();
      expect(cache.currentSize, _midCount ~/ 2);
      expect(cache.trimCount, before + 1);
    },
  );

  test('pressure BEFORE paused trims nothing either', () async {
    await lifecycle(AppLifecycleState.resumed);
    clock = clock.add(const Duration(seconds: 31));
    fillTo(1000);
    final int before = cache.trimCount;

    // The framework path, in the order a HOME press can deliver it:
    // UI_HIDDEN pressure with frames still on, then the lifecycle message.
    await pressure();
    expect(cache.trimPending, isTrue);
    await lifecycle(AppLifecycleState.paused);
    await _settled();

    expect(cache.currentSize, 1000);
    expect(cache.trimCount, before);
    expect(cache.lastTrimAt, isNot(clock));
    expect(logs, contains('[ImageCacheTuner] pending trim dropped (away)'));

    await lifecycle(AppLifecycleState.resumed);
    expect(cache.currentSize, 1000, reason: 'nothing trims on resume');
  });
}
