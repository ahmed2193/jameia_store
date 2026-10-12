// Locks HeroWidgetsBinding (lib/src/core/media/hero_widgets_binding.dart).
//
// Runs WITHOUT the test binding (plain `test`, never `testWidgets`): this
// isolate's only binding is the app's, exactly as in main(). The "a binding
// already exists" path is hero_widgets_binding_existing_test.dart, which needs
// its own isolate (each test file runs in one).

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_widgets_binding.dart';
import 'package:hero_mart/src/core/media/trimming_image_cache.dart';

void main() {
  test('creates the app binding with a TrimmingImageCache', () {
    final WidgetsBinding binding = HeroWidgetsBinding.ensureInitialized();

    expect(binding, isA<HeroWidgetsBinding>());
    expect(WidgetsBinding.instance, same(binding));
    expect(PaintingBinding.instance.imageCache, isA<TrimmingImageCache>());
  });

  test('a second call returns the same binding without asserting', () {
    final WidgetsBinding first = HeroWidgetsBinding.ensureInitialized();
    final WidgetsBinding second = HeroWidgetsBinding.ensureInitialized();

    expect(second, same(first));
  });

  test('leaving the foreground drops a pending pressure trim', () async {
    final HeroWidgetsBinding binding =
        HeroWidgetsBinding.ensureInitialized() as HeroWidgetsBinding;
    // framesEnabled needs a root widget, as after runApp.
    binding.attachRootWidget(const SizedBox());
    final TrimmingImageCache cache =
        PaintingBinding.instance.imageCache as TrimmingImageCache;
    final ui.Image image = await createTestImage(width: 2, height: 2);
    cache.putIfAbsent(
      'k',
      () => OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
      ),
    );
    expect(SchedulerBinding.instance.framesEnabled, isTrue);

    // The UI_HIDDEN pressure lands first (frames still on)...
    cache.clear();
    expect(cache.trimPending, isTrue);
    // ...then the lifecycle change: the binding forwards it to the cache.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(cache.trimPending, isFalse);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(cache.settleDelay * 2);
    expect(cache.currentSize, 1, reason: 'no trim after a quick return');
    expect(cache.trimCount, 0);
    cache.clearAll();
    image.dispose();
  });

  test('the framework pressure path trims instead of wiping', () async {
    final HeroWidgetsBinding binding =
        HeroWidgetsBinding.ensureInitialized() as HeroWidgetsBinding;
    binding.attachRootWidget(const SizedBox());
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final TrimmingImageCache cache =
        PaintingBinding.instance.imageCache as TrimmingImageCache;
    cache
      ..maximumSize = 4
      ..maximumSizeBytes = 4 * 16;
    final ui.Image image = await createTestImage(width: 2, height: 2);
    for (int i = 0; i < 4; i++) {
      cache.putIfAbsent(
        'p$i',
        () => OneFrameImageStreamCompleter(
          SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
        ),
      );
    }
    expect(cache.currentSize, 4);

    // The engine's memory-pressure message → ServicesBinding.
    // handleSystemMessage → PaintingBinding.handleMemoryPressure →
    // imageCache.clear(): a signal, not a wipe.
    ui.channelBuffers.push(
      SystemChannels.system.name,
      SystemChannels.system.codec.encodeMessage(<String, dynamic>{
        'type': 'memoryPressure',
      }),
      (ByteData? _) {},
    );
    expect(cache.currentSize, 4, reason: 'decided after the settle window');
    await Future<void>.delayed(cache.settleDelay * 2);
    expect(cache.currentSize, 2, reason: 'trimmed to half, never emptied');
    expect(cache.trimCount, 1);
    cache.clearAll();
    image.dispose();
  });

  test('hot-reload asset eviction still wipes every image at once', () async {
    final HeroWidgetsBinding binding =
        HeroWidgetsBinding.ensureInitialized() as HeroWidgetsBinding;
    binding.attachRootWidget(const SizedBox());
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final TrimmingImageCache cache =
        PaintingBinding.instance.imageCache as TrimmingImageCache;
    final int trimsBefore = cache.trimCount;
    final ui.Image image = await createTestImage(width: 2, height: 2);
    for (int i = 0; i < 3; i++) {
      cache.putIfAbsent(
        'e$i',
        () => OneFrameImageStreamCompleter(
          SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
        ),
      );
    }
    expect(cache.currentSize, 3);

    // `ext.flutter.evict`: not a pressure signal, so no settle window.
    binding.evict('assets/images/changed.png');

    expect(cache.currentSize, 0);
    expect(cache.trimPending, isFalse);
    expect(cache.trimCount, trimsBefore, reason: 'a wipe, not a trim');
    image.dispose();
  });
}

