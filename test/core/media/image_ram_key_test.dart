// Locks the in-RAM ImageCache key formula (lib/src/core/media/image_ram_key.dart)
// at runtime against the RESOLVED packages (cached_network_image 4.0.0,
// octo_image 2.1.0, Flutter 3.47.4): an entry seeded under
// imageRamKey(cacheKey, w, h) is exactly what `CachedNetworkImage(cacheKey:,
// memCacheWidth/Height:)` resolves — built here by HeroImage's
// HeroRetryingImage — so it paints in the first frame with no placeholder.
// The raw-URL fallback (same cacheKey, other URL) shares the entry; another
// decode size does not.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/media/image_ram_key.dart';
import 'package:hero_mart/src/core/media/image_request.dart';
import 'package:hero_mart/src/core/widgets/hero_image_loading_placeholder.dart';
import 'package:hero_mart/src/core/widgets/hero_image_shape.dart';
import 'package:hero_mart/src/core/widgets/hero_retrying_image.dart';

const String _cdn = 'https://media.jm3eia.com';

void _seed(Object key, ui.Image image) =>
    PaintingBinding.instance.imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
      ),
    );

Widget _host(Widget child) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

HeroRetryingImage _tile(String url, String cacheKey, int w, int h) =>
    HeroRetryingImage(
      request: ImageRequest(
        imageUrl: url,
        cacheKey: cacheKey,
        memCacheWidth: w,
        memCacheHeight: h,
      ),
      fit: BoxFit.cover,
      shape: const HeroImageShape(width: 100, height: 100),
      width: 100,
      height: 100,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // HeroRetryingImage hands CachedNetworkImage HeroImageCacheManager's
    // instance, which asks path_provider for its folders.
    final Directory tmp = Directory.systemTemp.createTempSync(
      'hero_img_ram_key_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tmp.path,
        );
  });

  setUp(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  test('the key: ResizeImageKey(provider[cacheKey], w, h); url not part', () {
    const String key = '$_cdn/k.jpeg?w=270&h=270&fit=cover&format=webp';
    final Object k = imageRamKey(key, 270, 270);
    expect(k, isA<ResizeImageKey>());
    expect(k, imageRamKey(key, 270, 270));
    expect(k == imageRamKey(key, 324, 324), isFalse, reason: 'size-exact');
    expect(k == imageRamKey('$key&x=1', 270, 270), isFalse);
    // Unsized: the provider itself, whose equality reads cacheKey ?? url.
    final Object bare = imageRamKey(key, null, null);
    expect(bare, isA<CachedNetworkImageProvider>());
    expect(
      bare,
      const CachedNetworkImageProvider('$_cdn/k.jpeg', cacheKey: key),
      reason: 'another URL under the same cacheKey is the same entry',
    );
  });

  testWidgets('a seeded key paints today\'s tile synchronously', (
    WidgetTester tester,
  ) async {
    final ImageVariant v = ImageVariant.of(
      '$_cdn/2026/10/9/ram.jpeg',
      wireW: 270,
      wireH: 270,
      fit: 'cover',
      format: 'webp',
    );
    final ui.Image img = (await tester.runAsync(
      () => createTestImage(width: 2, height: 2),
    ))!;
    addTearDown(img.dispose);
    expect(imageRamLanded(imageRamStatus(v.cacheKey, 270, 270)), isFalse);
    _seed(imageRamKey(v.cacheKey, 270, 270), img);
    expect(imageRamLanded(imageRamStatus(v.cacheKey, 270, 270)), isTrue);
    expect(imageRamKeyLanded(variantRamKey(v)), isTrue);

    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _tile(v.cacheKey, v.cacheKey, 270, 270),
            // The EXIF raw fallback: other URL, SAME cacheKey → same entry.
            _tile(v.rawUrl, v.cacheKey, 270, 270),
          ],
        ),
      ),
    );

    expect(
      find.byType(HeroImageLoadingPlaceholder),
      findsNothing,
      reason: 'no placeholder frame',
    );
    final Iterable<RawImage> raws = tester.widgetList<RawImage>(
      find.byType(RawImage),
    );
    expect(raws, hasLength(2));
    expect(raws.every((RawImage r) => r.image != null), isTrue);
    expect(PaintingBinding.instance.imageCache.currentSize, 1);

    // On screen = live: still landed after the LRU entry is gone, where
    // `containsKey` would already say no.
    PaintingBinding.instance.imageCache.clear();
    final Object k = imageRamKey(v.cacheKey, 270, 270);
    expect(PaintingBinding.instance.imageCache.containsKey(k), isFalse);
    expect(imageRamKeyLanded(k), isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
