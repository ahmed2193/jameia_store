// Shared fixtures of the HeroImage pipeline tests (test/core/widgets/
// hero_image/), ported from the reference's app_image_transition_test.dart.
// RAM entries are seeded under the EXACT key the package decodes under
// (image_ram_key.dart); a load that should stay in flight is seeded as a
// pending completer; real disk / network I/O never completes inside the
// fake-async test zone. The shimmer deadline runs on ImagePlaceholderClock,
// pointed at the fake clock.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_cdn_transform.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/media/image_load_policy.dart';
import 'package:hero_mart/src/core/media/image_placeholder_anchor.dart';
import 'package:hero_mart/src/core/media/image_ram_key.dart';
import 'package:hero_mart/src/core/media/image_variant_index.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_attempt_key.dart';

const String cdn = 'https://media.jm3eia.com';

/// The URL a [dp]-square HeroImage of [raw] requests at DPR 2: 100 dp =
/// 200 px → rung 225; 220 dp = 440 px → rung 467.
String urlFor(String raw, double dp) =>
    HeroImage.cdnUrl(url: raw, width: dp, height: dp, dpr: 2);

Widget host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduced = false,
}) => MediaQuery(
  data: MediaQueryData(devicePixelRatio: 2, disableAnimations: reduced),
  child: Directionality(
    textDirection: direction,
    child: Center(child: child),
  ),
);

/// Burns [cost] of fake time ONCE, in the paint phase: after every build and
/// layout of the frame (the tiles are mounted by then) and before its
/// post-frame callbacks. No timer fires meanwhile, as on a blocked main
/// isolate. The fake-async version of a cold-start first frame that takes
/// over a second (`pumpWidget(duration:)` cannot separate mount from frame).
class SlowFrame extends CustomPainter {
  SlowFrame(this.cost);

  final Duration cost;
  bool _spent = false;

  @override
  void paint(Canvas canvas, Size size) {
    if (_spent) return;
    _spent = true;
    (TestWidgetsFlutterBinding.instance as AutomatedTestWidgetsFlutterBinding)
        .elapseBlocking(cost);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget slowFrameHost(Widget tile, Duration cost) => host(
  Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      tile,
      SizedBox.square(
        dimension: 1,
        child: CustomPaint(painter: SlowFrame(cost)),
      ),
    ],
  ),
);

void seedRam(String key, int px, ui.Image image) =>
    PaintingBinding.instance.imageCache.putIfAbsent(
      imageRamKey(key, px, px),
      () => OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
      ),
    );

/// A load of [key] that is in flight until the returned completer completes.
Completer<ImageInfo> seedPending(String key, int px) {
  final Completer<ImageInfo> c = Completer<ImageInfo>();
  PaintingBinding.instance.imageCache.putIfAbsent(
    imageRamKey(key, px, px),
    () => OneFrameImageStreamCompleter(c.future),
  );
  return c;
}

CachedNetworkImage cni(WidgetTester t) =>
    t.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

/// The inner CachedNetworkImage key: raw-fallback bit, attempt, remount
/// epoch (HeroRetryingImage).
HeroImageAttemptKey innerKey(int attempt, {bool raw = false, int epoch = 0}) =>
    HeroImageAttemptKey(epoch: epoch, attempt: attempt, raw: raw);

/// Whether a clone of [image] is on screen.
bool painted(WidgetTester t, ui.Image image) => t
    .widgetList<RawImage>(find.byType(RawImage))
    .any((RawImage r) => r.image?.isCloneOf(image) ?? false);

/// Every load fails with [error]: by default a CDN 500, the way an
/// EXIF-broken transform does.
class FailingLoader extends Fake implements BaseCacheManager {
  FailingLoader([
    this.error = const HttpExceptionWithStatus(500, 'transform failed'),
  ]);

  final Object error;
  final List<String> urls = <String>[];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    urls.add(url);
    return Stream<FileResponse>.error(error);
  }

  @override
  Future<void> removeFile(String key) async {}
}

/// Every load stays in flight: the stream never emits.
class SilentLoader extends Fake implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => StreamController<FileResponse>().stream;
}

/// Distinct bitmaps (no createTestImage cache), so isCloneOf tells them
/// apart.
class TestImages {
  int _side = 2;

  Future<ui.Image> next(WidgetTester t) async {
    final int s = _side++;
    final ui.Image img = (await t.runAsync(
      () => createTestImage(width: s, height: s, cache: false),
    ))!;
    addTearDown(img.dispose);
    return img;
  }
}

/// The pipeline's test seams for one test file: path_provider answers a temp
/// folder (the real manager asks it for its folders), no store hint, no
/// disk-index seed, the shimmer deadline on the fake clock; every test starts
/// with empty RAM, indexes, loader override and transform registry.
void setUpImagePipeline() {
  setUpAll(() {
    final Directory tmp = Directory.systemTemp.createTempSync('hero_image_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tmp.path,
        );
    ImageLoadPolicy.storeHint = (_) => false;
    ImageLoadPolicy.startDiskSeed = () async => 0;
    ImagePlaceholderClock.debugNowUs = () =>
        TestWidgetsFlutterBinding.instance.clock.now().microsecondsSinceEpoch;
  });

  tearDownAll(() {
    ImagePlaceholderClock.debugNowUs = null;
    ImageLoadPolicy.startDiskSeed = HeroImageCacheManager.seedDiskIndex;
  });

  setUp(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    ImageDiskIndex.instance.reset();
    ImageVariantIndex.instance.reset();
    ImageCdnTransform.debugReset();
    HeroImageCacheManager.debugLoaderOverride = null;
  });

  tearDown(() => HeroImageCacheManager.debugLoaderOverride = null);
}
