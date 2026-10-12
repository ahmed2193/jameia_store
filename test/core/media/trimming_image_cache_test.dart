// Locks TrimmingImageCache (lib/src/core/media/trimming_image_cache.dart):
// memory pressure trims the LRU to half the limits instead of wiping, at most
// once per 30 s, and only if the app is still in front once the 400 ms settle
// window has passed — in BOTH orders a HOME press produces (pressure before
// `hidden`, and `hidden` before pressure) — and a trim that evicted something
// asks for a frame, so an idle screen frees the bitmaps.
//
// The settle window runs on the widget tester's fake clock
// (`tester.binding.delayed`): this repo has no direct `fake_async`
// dependency. Every test ends with no settle timer pending. Lifecycle
// messages are delivered synchronously by the test messenger.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_load_trace.dart';
import 'package:hero_mart/src/core/media/media_log.dart';
import 'package:hero_mart/src/core/media/trimming_image_cache.dart';

/// 10×10 test images → 400 bytes per entry in the cache.
const int _entryBytes = 10 * 10 * 4;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TrimmingImageCache cache;
  late DateTime clock;
  late ui.Image image;

  void seed(Iterable<int> ids) {
    for (final int id in ids) {
      cache.putIfAbsent(
        'k$id',
        () => OneFrameImageStreamCompleter(
          SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
        ),
      );
    }
  }

  // The platform's lifecycle message, as the engine sends it. `hidden` and
  // `paused` turn SchedulerBinding.framesEnabled off, `resumed` turns it on.
  Future<void> lifecycle(AppLifecycleState state) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            SystemChannels.lifecycle.name,
            SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
            (_) {},
          );

  /// Attaches a root widget (framesEnabled needs one, as after runApp),
  /// makes the image and the cache under test.
  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await lifecycle(AppLifecycleState.resumed);
    image = (await tester.runAsync(
      () => createTestImage(width: 10, height: 10),
    ))!;
    clock = DateTime(2026, 10, 8, 12);
    cache = TrimmingImageCache()
      ..now = (() => clock)
      ..maximumSize = 10
      ..maximumSizeBytes = 10 * _entryBytes;
    addTearDown(() {
      cache
        ..clearAll()
        ..clearLiveImages();
      image.dispose();
    });
  }

  // Lets the 400 ms settle window run out on the fake clock.
  Future<void> settle(WidgetTester tester) =>
      tester.binding.delayed(cache.settleDelay);

  testWidgets('clear() trims LRU entries to half the limits and restores', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    expect(cache.currentSize, 10);
    expect(cache.currentSizeBytes, 10 * _entryBytes);

    cache.clear();

    // Decided after the settle window, not on the signal.
    expect(cache.settleDelay, const Duration(milliseconds: 400));
    expect(cache.trimPending, isTrue);
    await tester.binding.delayed(const Duration(milliseconds: 399));
    expect(cache.currentSize, 10);
    await tester.binding.delayed(const Duration(milliseconds: 1));
    expect(cache.trimPending, isFalse);
    expect(cache.currentSize, 5);
    expect(cache.currentSizeBytes, 5 * _entryBytes);
    expect(cache.maximumSize, 10);
    expect(cache.maximumSizeBytes, 10 * _entryBytes);
    // Least-recently-used went first; the recent half stayed.
    for (int i = 0; i < 5; i++) {
      expect(cache.containsKey('k$i'), isFalse, reason: 'k$i');
    }
    for (int i = 5; i < 10; i++) {
      expect(cache.containsKey('k$i'), isTrue, reason: 'k$i');
    }
    expect(cache.trimCount, 1);
    expect(cache.lastTrimAt, clock);
    expect(cache.lastTrim?.entriesBefore, 10);
    expect(cache.lastTrim?.entriesAfter, 5);
    expect(cache.lastTrim?.bytesBefore, 10 * _entryBytes);
    expect(cache.lastTrim?.bytesAfter, 5 * _entryBytes);
  });

  testWidgets('a live image survives the trim and resolves without a reload', (
    WidgetTester tester,
  ) async {
    await start(tester);
    final ImageStreamCompleter live = cache.putIfAbsent(
      'live',
      () => OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
      ),
    )!;
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, _) => info.dispose(),
    );
    live.addListener(listener);
    // An on-screen image is re-resolved with its listener attached (what
    // ImageProvider.resolve does on rebuild) → tracked as live.
    expect(cache.putIfAbsent('live', () => fail('cached')), same(live));
    expect(cache.statusForKey('live').live, isTrue);
    // Nine newer entries make it the least recently used one.
    seed(List<int>.generate(9, (int i) => i));

    cache.clear();
    await settle(tester);

    // Its keep-alive slot went with the LRU half; the live entry did not.
    expect(cache.currentSize, 5);
    expect(cache.statusForKey('live').keepAlive, isFalse);
    expect(cache.statusForKey('live').live, isTrue);
    final ImageStreamCompleter? again = cache.putIfAbsent(
      'live',
      () => fail('a live image must not be reloaded'),
    );
    expect(again, same(live));
    live.removeListener(listener);
  });

  testWidgets('rate limit: one trim per window, then trims again', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    cache.clear();
    await settle(tester);
    expect(cache.currentSize, 5);

    // Refill; a burst inside the 30 s window is a no-op (no settle timer).
    seed(List<int>.generate(5, (int i) => 10 + i));
    expect(cache.currentSize, 10);
    clock = clock.add(const Duration(milliseconds: 5));
    cache
      ..clear()
      ..clear()
      ..clear();
    expect(cache.trimPending, isFalse);
    clock = clock.add(const Duration(seconds: 29));
    cache.clear();
    await settle(tester);
    expect(cache.currentSize, 10);
    expect(cache.trimCount, 1);

    clock = clock.add(const Duration(seconds: 1));
    cache.clear();
    await settle(tester);
    expect(cache.currentSize, 5);
    expect(cache.trimCount, 2);
    expect(cache.maximumSize, 10);
    expect(cache.maximumSizeBytes, 10 * _entryBytes);
  });

  testWidgets('an empty cache does not open a rate-limit window', (
    WidgetTester tester,
  ) async {
    await start(tester);
    cache.clear();
    expect(cache.trimPending, isFalse);
    expect(cache.trimCount, 0);
    expect(cache.lastTrimAt, isNull);

    seed(List<int>.generate(10, (int i) => i));
    cache.clear();
    await settle(tester);
    expect(cache.currentSize, 5);
  });

  testWidgets('a second signal restarts the window; the burst trims once', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    cache.clear();
    await tester.binding.delayed(const Duration(milliseconds: 300));
    cache.clear();
    await tester.binding.delayed(const Duration(milliseconds: 300));
    expect(cache.currentSize, 10, reason: '300 ms after the second signal');
    expect(cache.trimPending, isTrue);
    await tester.binding.delayed(const Duration(milliseconds: 100));
    expect(cache.currentSize, 5);
    expect(cache.trimCount, 1);
  });

  testWidgets('pressure, then hidden inside the window: no trim', (
    WidgetTester tester,
  ) async {
    await start(tester);
    // The backgrounding's own UI_HIDDEN signal arrived while frames still
    // ran; the lifecycle message came right after. Nothing forwards the
    // lifecycle to handleLifecycle under the test binding, so this is the
    // window-end re-check on its own.
    for (final AppLifecycleState state in <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      await lifecycle(AppLifecycleState.resumed);
      seed(List<int>.generate(10, (int i) => i));
      cache.clear();
      expect(cache.trimPending, isTrue, reason: '$state');
      await tester.binding.delayed(const Duration(milliseconds: 7));
      await lifecycle(state);
      expect(SchedulerBinding.instance.framesEnabled, isFalse);
      await settle(tester);

      expect(cache.trimPending, isFalse, reason: '$state');
      expect(cache.currentSize, 10, reason: '$state');
      expect(cache.trimCount, 0, reason: '$state');
      expect(cache.lastTrimAt, isNull, reason: '$state');
    }
    await lifecycle(AppLifecycleState.resumed);
  });

  testWidgets('hidden, then pressure: deferred at once, no window', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    await lifecycle(AppLifecycleState.hidden);
    cache.clear();
    expect(cache.trimPending, isFalse);
    await settle(tester);
    expect(cache.currentSize, 10);
    expect(cache.trimCount, 0);
    await lifecycle(AppLifecycleState.resumed);
  });

  testWidgets('handleLifecycle drops a pending trim even if the app returns', (
    WidgetTester tester,
  ) async {
    await start(tester);
    // What HeroWidgetsBinding forwards: a quick HOME-and-back inside the
    // window must not trim on return either.
    seed(List<int>.generate(10, (int i) => i));
    cache.clear();
    cache.handleLifecycle(AppLifecycleState.inactive);
    expect(cache.trimPending, isTrue, reason: 'inactive still draws');
    cache.handleLifecycle(AppLifecycleState.hidden);
    expect(cache.trimPending, isFalse);
    cache.handleLifecycle(AppLifecycleState.resumed);
    await settle(tester);
    expect(cache.currentSize, 10);
    expect(cache.trimCount, 0);

    // The next signal with the app in front trims as usual.
    cache.clear();
    await settle(tester);
    expect(cache.currentSize, 5);
  });

  testWidgets('with frames off (hidden/paused) clear() trims nothing', (
    WidgetTester tester,
  ) async {
    await start(tester);
    // A trim there frees no memory (evicted bitmaps are released in a
    // post-frame callback, and no frame runs until resume) and only costs the
    // cache on return. The skipped call must not open the rate-limit window.
    seed(List<int>.generate(10, (int i) => i));
    for (final AppLifecycleState state in <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      await lifecycle(state);
      expect(
        SchedulerBinding.instance.framesEnabled,
        isFalse,
        reason: '$state',
      );

      cache.clear();
      await settle(tester);

      expect(cache.currentSize, 10, reason: '$state');
      expect(cache.currentSizeBytes, 10 * _entryBytes, reason: '$state');
      expect(cache.trimCount, 0, reason: '$state');
      expect(cache.lastTrimAt, isNull, reason: '$state');
      expect(cache.lastTrim, isNull, reason: '$state');
      expect(cache.maximumSize, 10);
      expect(cache.maximumSizeBytes, 10 * _entryBytes);
    }

    // Back on screen the next signal trims, with no window left behind.
    await lifecycle(AppLifecycleState.resumed);
    expect(SchedulerBinding.instance.framesEnabled, isTrue);
    cache.clear();
    await settle(tester);
    expect(cache.currentSize, 5);
    expect(cache.trimCount, 1);
    expect(cache.lastTrimAt, clock);
  });

  testWidgets('a trim that evicts on an idle screen schedules a frame', (
    WidgetTester tester,
  ) async {
    await start(tester);
    // Evicted bitmaps are released in a post-frame callback, and an idle
    // foreground screen runs none: the trim asks for one.
    await tester.pump();
    expect(
      SchedulerBinding.instance.hasScheduledFrame,
      isFalse,
      reason: 'idle',
    );

    // Under the trimmed limits already: nothing evicted, no frame.
    seed(<int>[0, 1, 2]);
    cache.clear();
    await settle(tester);
    expect(cache.trimCount, 1);
    expect(cache.currentSize, 3);
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

    clock = clock.add(cache.minInterval);
    seed(List<int>.generate(7, (int i) => 3 + i));
    cache.clear();
    await settle(tester);
    expect(cache.trimCount, 2);
    expect(cache.currentSize, 5);
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
    await tester.pump(); // that frame frees the evicted bitmaps
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
  });

  testWidgets('a limit of 0 still wipes with frames off', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    await lifecycle(AppLifecycleState.paused);

    cache.maximumSize = 0;

    expect(cache.currentSize, 0);
    expect(cache.currentSizeBytes, 0);
    await lifecycle(AppLifecycleState.resumed);
  });

  testWidgets('clearAll() empties everything at once, drops a pending trim', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    cache.clear();
    expect(cache.trimPending, isTrue);
    cache.clearAll();

    expect(cache.trimPending, isFalse);
    expect(cache.currentSize, 0);
    expect(cache.currentSizeBytes, 0);
    expect(cache.maximumSize, 10);
  });

  testWidgets('setting a limit to 0 still empties the cache', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    cache.clear();
    cache.maximumSize = 0;

    expect(cache.trimPending, isFalse);
    expect(cache.currentSize, 0);
    expect(cache.currentSizeBytes, 0);
  });

  testWidgets('trim cost: a 300-entry cache trims to 150 and traces it', (
    WidgetTester tester,
  ) async {
    await start(tester);
    // Benchmark-style: the counters, never the time.
    const int n = 300;
    cache
      ..maximumSize = n
      ..maximumSizeBytes = n * _entryBytes;
    seed(List<int>.generate(n, (int i) => i));
    expect(cache.currentSize, n);

    final List<String> logs = <String>[];
    MediaLog.debugSink = (String name, String m) =>
        logs.add(MediaLog.format(name, m));
    ImageLoadTrace.enabled = true;
    try {
      cache.clear();
      await settle(tester);
    } finally {
      ImageLoadTrace.enabled = false;
      MediaLog.debugSink = null;
    }

    expect(cache.trimCount, 1);
    expect(cache.lastTrim?.entriesBefore, n);
    expect(cache.lastTrim?.entriesAfter, n ~/ 2);
    expect(cache.lastTrim?.bytesBefore, n * _entryBytes);
    expect(cache.lastTrim?.bytesAfter, n ~/ 2 * _entryBytes);
    final List<String> trace = logs
        .where((String l) => l.startsWith('[IMGCACHE] trim '))
        .toList();
    expect(trace, hasLength(1));
    expect(
      trace.single,
      matches(
        RegExp(
          r'^\[IMGCACHE\] trim evicted=150 entries 59 KB '
          r'\(300→150, 120000→60000 B\) live=0 us=\d+$',
        ),
      ),
    );
    expect(
      logs,
      contains(
        '[ImageCacheTuner] pressure → trimmed 300→150 entries / 0.1→0.1 MB '
        '(#1, live=0, cap 0.1 MB/300)',
      ),
    );
  });

  testWidgets('no [IMGCACHE] trim line while the trace is off', (
    WidgetTester tester,
  ) async {
    await start(tester);
    seed(List<int>.generate(10, (int i) => i));
    final List<String> logs = <String>[];
    MediaLog.debugSink = (String name, String m) =>
        logs.add(MediaLog.format(name, m));
    try {
      cache.clear();
      await settle(tester);
    } finally {
      MediaLog.debugSink = null;
    }
    expect(cache.currentSize, 5);
    expect(logs.where((String l) => l.startsWith('[IMGCACHE]')), isEmpty);
    expect(
      logs,
      contains('[ImageCacheTuner] pressure → trim pending (400 ms)'),
      reason: 'the tuner lines stay on in debug',
    );
  });
}
