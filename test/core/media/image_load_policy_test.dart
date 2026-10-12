// Locks the load-source probe (lib/src/core/media/image_load_policy.dart):
// exact RAM key → disk-known → another variant of the asset complete in RAM
// → network, and what each decision carries (placeholder provider + its RAM
// key, fades, shimmer delay); the per-variant RAM key cache; the fidelity
// floor; afterSeed; and the disk-index seed the first decision starts after
// its frame. RAM entries are seeded under the EXACT key the package uses
// (image_ram_key.dart, locked against cached_network_image 4.0.0 in
// image_ram_key_test.dart).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/media/image_load_policy.dart';
import 'package:hero_mart/src/core/media/image_ram_key.dart';
import 'package:hero_mart/src/core/media/image_variant_index.dart';

const String _cdn = 'https://media.jm3eia.com';
const Duration _fadeIn = Duration(milliseconds: 280);
const Duration _fadeOut = Duration(milliseconds: 160);

ImageVariant _v(String asset, int w) =>
    ImageVariant.of(asset, wireW: w, wireH: w, fit: 'cover', format: 'webp');

Object _keyOf(ImageProvider<Object> p) {
  Object out = p;
  p.obtainKey(ImageConfiguration.empty).then((Object k) => out = k);
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ui.Image img;
  late ImageDiskIndex disk;
  late ImageVariantIndex variants;
  final Set<String> storeKeys = <String>{};
  int seedCalls = 0;

  setUpAll(() async {
    // Observe the disk-index seed instead of reading the real metadata file.
    ImageLoadPolicy.startDiskSeed = () async {
      seedCalls++;
      return 0;
    };
    // The variant provider names HeroImageCacheManager.loader, which creates
    // the real manager, which asks path_provider for its folders.
    final Directory tmp = Directory.systemTemp.createTempSync(
      'hero_img_load_policy_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tmp.path,
        );
    ImageLoadPolicy.storeHint = storeKeys.contains;
    img = await createTestImage(width: 2, height: 2);
  });

  tearDownAll(() => img.dispose());

  setUp(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    disk = ImageDiskIndex();
    variants = ImageVariantIndex();
    storeKeys.clear();
  });

  void seedRam(ImageVariant v) =>
      PaintingBinding.instance.imageCache.putIfAbsent(
        imageRamKey(v.cacheKey, v.wireW, v.wireH),
        () => OneFrameImageStreamCompleter(
          SynchronousFuture<ImageInfo>(ImageInfo(image: img.clone())),
        ),
      );

  ImageLoadDecision decide(ImageVariant v, {bool withAsset = true}) =>
      ImageLoadPolicy.decide(
        cacheKey: v.cacheKey,
        memW: v.wireW,
        memH: v.wireH,
        assetId: withAsset ? v.assetId : null,
        networkFadeIn: _fadeIn,
        networkFadeOut: _fadeOut,
        diskIndex: disk,
        variantIndex: variants,
      );

  test('exact RAM key → ram, and the key is now known on disk', () {
    final ImageVariant v = _v('$_cdn/r.jpeg', 225);
    seedRam(v);
    disk.markSeen('unrelated');
    final ImageLoadDecision d = decide(v);
    expect(d.source, ImageLoadSource.ram);
    expect(d.fadeIn, Duration.zero);
    expect(d.placeholderProvider, isNull);
    expect(
      disk.contains(v.cacheKey),
      isTrue,
      reason: 'a RAM hit came off disk',
    );
    // The RAM key is size-exact: another decode size of it is not a RAM hit.
    expect(
      ImageLoadPolicy.decide(
        cacheKey: v.cacheKey,
        memW: 467,
        memH: 467,
        assetId: null,
        networkFadeIn: _fadeIn,
        networkFadeOut: _fadeOut,
        diskIndex: ImageDiskIndex(),
        variantIndex: variants,
      ).source,
      ImageLoadSource.network,
    );
  });

  test(
    'disk-known (index or store metadata) → disk: no fade, late shimmer',
    () {
      final ImageVariant a = _v('$_cdn/d1.jpeg', 225);
      final ImageVariant b = _v('$_cdn/d2.jpeg', 225);
      disk.markDownloaded(a.cacheKey);
      storeKeys.add(b.cacheKey);
      for (final ImageVariant v in <ImageVariant>[a, b]) {
        final ImageLoadDecision d = decide(v);
        expect(d.source, ImageLoadSource.disk);
        expect(d.fadeIn, Duration.zero);
        expect(d.fadeOut, Duration.zero);
        expect(d.shimmerDelay, ImageLoadPolicy.diskShimmerDelay);
        expect(d.shimmerDelay, const Duration(seconds: 1));
        expect(d.placeholderProvider, isNull);
        expect(d.placeholderRamKey, isNull);
      }
    },
  );

  test('another size complete in RAM → variant, painting THAT RAM entry', () {
    const String asset = '$_cdn/v.jpeg';
    final ImageVariant small = _v(asset, 225);
    final ImageVariant want = _v(asset, 467);
    variants
      ..record(asset, small)
      ..record(asset, want);
    seedRam(small);

    final ImageLoadDecision d = decide(want);
    expect(d.source, ImageLoadSource.variant);
    expect(d.fadeIn, Duration.zero);
    expect(d.fadeOut, Duration.zero);
    final ImageCacheStatus st = PaintingBinding.instance.imageCache
        .statusForKey(_keyOf(d.placeholderProvider!));
    expect(
      imageRamLanded(st),
      isTrue,
      reason: 'the placeholder provider resolves to the seeded entry',
    );
    expect(
      _keyOf(d.placeholderProvider!),
      imageRamKey(small.cacheKey, 225, 225),
    );
    // The provider's RAM key travels with it, for the retry re-check.
    expect(d.placeholderRamKey, _keyOf(d.placeholderProvider!));
    expect(identical(d.placeholderRamKey, variantRamKey(small)), isTrue);
    expect(imageRamKeyLanded(d.placeholderRamKey!), isTrue);
    PaintingBinding.instance.imageCache.clear();
    expect(
      imageRamKeyLanded(d.placeholderRamKey!),
      isFalse,
      reason: 'an evicted variant reads as gone',
    );
  });

  test('RAM keys are built once per variant; the tile reuses its own', () {
    final ImageVariant v = _v('$_cdn/key.jpeg', 225);
    final Object k = variantRamKey(v);
    expect(k, imageRamKey(v.cacheKey, 225, 225));
    expect(identical(variantRamKey(v), k), isTrue, reason: 'cached');
    // The tile that IS the variant reads the cached key...
    expect(identical(tileRamKey(v.cacheKey, 225, 225, v), k), isTrue);
    // ...anything else builds its own (other size, other key, no variant).
    expect(identical(tileRamKey(v.cacheKey, 467, 467, v), k), isFalse);
    expect(
      tileRamKey(v.cacheKey, 467, 467, v),
      imageRamKey(v.cacheKey, 467, 467),
    );
    expect(identical(tileRamKey('${v.assetId}?raw', 225, 225, v), k), isFalse);
    expect(tileRamKey(v.cacheKey, 225, 225, null), k, reason: 'equal key');
    // decide() with the tile's variant finds the RAM hit through that key.
    seedRam(v);
    final ImageLoadDecision d = ImageLoadPolicy.decide(
      cacheKey: v.cacheKey,
      memW: 225,
      memH: 225,
      assetId: v.assetId,
      networkFadeIn: _fadeIn,
      networkFadeOut: _fadeOut,
      variant: v,
      diskIndex: disk,
      variantIndex: variants,
    );
    expect(d.source, ImageLoadSource.ram);
  });

  testWidgets(
    'the first decision starts the disk-index seed once, post-frame',
    (WidgetTester t) async {
      // Flush callbacks the plain tests above left pending, then start over.
      await t.pump();
      seedCalls = 0;
      ImageLoadPolicy.debugResetSeed();

      final ImageVariant v = _v('$_cdn/seed.jpeg', 225);
      decide(v);
      decide(v);
      expect(seedCalls, 0, reason: 'never inside the deciding frame');
      await t.pump();
      expect(seedCalls, 1);
      decide(_v('$_cdn/seed2.jpeg', 467));
      await t.pump();
      await t.pump();
      expect(seedCalls, 1, reason: 'once per process');
    },
  );

  test('variant choice: narrowest at or above, else widest below', () {
    const String asset = '$_cdn/pick.jpeg';
    final ImageVariant v150 = _v(asset, 150);
    final ImageVariant v225 = _v(asset, 225);
    final ImageVariant v467 = _v(asset, 467);
    final ImageVariant v548 = _v(asset, 548);
    final ImageVariant v900 = _v(asset, 900);
    for (final ImageVariant v in <ImageVariant>[v150, v225, v467, v548, v900]) {
      variants.record(asset, v);
    }
    Object chosen() => _keyOf(decide(v467).placeholderProvider!);

    // Only smaller ones in RAM: the widest of them (it upscales least).
    seedRam(v150);
    expect(chosen(), imageRamKey(v150.cacheKey, 150, 150));
    seedRam(v225);
    expect(chosen(), imageRamKey(v225.cacheKey, 225, 225));
    // A larger one beats any smaller one (it downscales sharply).
    seedRam(v900);
    expect(
      chosen(),
      imageRamKey(v900.cacheKey, 900, 900),
      reason: 'a cached larger variant beats the smaller ones',
    );
    seedRam(v548);
    expect(
      chosen(),
      imageRamKey(v548.cacheKey, 548, 548),
      reason: 'of the larger ones, the narrowest',
    );
  });

  test('225 and 548 cached for a 467 request → 548; only 225 → 225', () {
    const String asset = '$_cdn/flip.jpeg';
    final ImageVariant v225 = _v(asset, 225);
    final ImageVariant v467 = _v(asset, 467);
    final ImageVariant v548 = _v(asset, 548);
    // Smaller one recorded first, then larger first: order must not matter.
    for (final List<ImageVariant> order in <List<ImageVariant>>[
      <ImageVariant>[v225, v467, v548],
      <ImageVariant>[v548, v467, v225],
    ]) {
      variants.reset();
      PaintingBinding.instance.imageCache.clear();
      for (final ImageVariant v in order) {
        variants.record(asset, v);
      }
      seedRam(v225);
      expect(
        _keyOf(decide(v467).placeholderProvider!),
        imageRamKey(v225.cacheKey, 225, 225),
        reason: 'only the smaller one is cached: it is still the best',
      );
      seedRam(v548);
      expect(
        _keyOf(decide(v467).placeholderProvider!),
        imageRamKey(v548.cacheKey, 548, 548),
        reason: 'the larger cached one wins over the smaller',
      );
    }
  });

  test('an uncached larger variant does not hide a cached smaller one', () {
    const String asset = '$_cdn/skip.jpeg';
    final ImageVariant v225 = _v(asset, 225);
    final ImageVariant v467 = _v(asset, 467);
    final ImageVariant v548 = _v(asset, 548); // recorded, but not in RAM
    variants
      ..record(asset, v548)
      ..record(asset, v225)
      ..record(asset, v467);
    seedRam(v225);
    expect(
      _keyOf(decide(v467).placeholderProvider!),
      imageRamKey(v225.cacheKey, 225, 225),
    );
  });

  test('priority: RAM beats disk beats variant', () {
    const String asset = '$_cdn/prio.jpeg';
    final ImageVariant small = _v(asset, 225);
    final ImageVariant want = _v(asset, 467);
    variants
      ..record(asset, small)
      ..record(asset, want);
    seedRam(small);
    disk.markDownloaded(want.cacheKey);
    expect(decide(want).source, ImageLoadSource.disk);
    seedRam(want);
    expect(decide(want).source, ImageLoadSource.ram);
  });

  test('nothing known → network with the tile fades and the 300 ms delay', () {
    const String asset = '$_cdn/n.jpeg';
    final ImageVariant small = _v(asset, 225);
    final ImageVariant want = _v(asset, 467);
    variants
      ..record(asset, small)
      ..record(asset, want);
    // Indexed but not in RAM: no variant placeholder.
    ImageLoadDecision d = decide(want);
    expect(d.source, ImageLoadSource.network);
    expect(d.fadeIn, _fadeIn);
    expect(d.fadeOut, _fadeOut);
    expect(d.shimmerDelay, ImageLoadPolicy.networkShimmerDelay);
    expect(d.shimmerDelay, const Duration(milliseconds: 300));
    expect(d.placeholderProvider, isNull);
    // In RAM, but no asset id (a non-CDN host): still network.
    seedRam(small);
    d = decide(want, withAsset: false);
    expect(d.source, ImageLoadSource.network);
  });

  group('fidelity floor', () {
    ImageVariant rung(String asset, int w, int h) => ImageVariant.of(
      asset,
      wireW: w,
      wireH: h,
      fit: 'cover',
      format: 'webp',
    );

    test('floor = wire width / 4, rounded up', () {
      expect(ImageLoadPolicy.maxVariantUpscale, 4);
      expect(ImageLoadPolicy.minVariantWidth(764), 191);
      expect(ImageLoadPolicy.minVariantWidth(900), 225);
      expect(ImageLoadPolicy.minVariantWidth(467), 117);
      expect(ImageLoadPolicy.minVariantWidth(50), 13);
    });

    test('a 50x50 logo rung never paints a 764x204 store hero', () {
      const String asset = '$_cdn/2026/7/4673a15d.jpeg';
      final ImageVariant logo = rung(asset, 50, 50);
      final ImageVariant card = rung(asset, 185, 96);
      final ImageVariant hero = rung(asset, 764, 204);
      for (final ImageVariant v in <ImageVariant>[logo, card, hero]) {
        variants.record(asset, v);
      }
      seedRam(logo);
      seedRam(card);

      // 15.3x and 4.1x upscales: below the floor, so the hero's own network
      // path (still box → shimmer) instead of a blurry crop.
      final ImageLoadDecision d = decide(hero);
      expect(d.source, ImageLoadSource.network);
      expect(d.placeholderProvider, isNull);
      expect(d.fadeIn, _fadeIn);
    });

    test('the grid tile → product-page hero hop (225 → 764) stands in', () {
      const String asset = '$_cdn/2025/9/8/8d99cfe2.jpeg';
      final ImageVariant logo = rung(asset, 50, 50);
      final ImageVariant tile = rung(asset, 225, 210);
      final ImageVariant pdp = rung(asset, 764, 713);
      for (final ImageVariant v in <ImageVariant>[logo, tile, pdp]) {
        variants.record(asset, v);
      }
      seedRam(logo);
      expect(
        decide(pdp).source,
        ImageLoadSource.network,
        reason: 'only the 50 px rung is in RAM',
      );
      seedRam(tile);
      final ImageLoadDecision d = decide(pdp);
      expect(d.source, ImageLoadSource.variant);
      expect(
        _keyOf(d.placeholderProvider!),
        imageRamKey(tile.cacheKey, 225, 210),
      );

      // The same hop on a dpr-2 phone lands the hero on rung 900: 225 → 900
      // is exactly 4.0x and must still stand in.
      final ImageVariant pdp900 = rung(asset, 900, 840);
      variants.record(asset, pdp900);
      final ImageLoadDecision d900 = decide(pdp900);
      expect(d900.source, ImageLoadSource.variant);
      expect(
        _keyOf(d900.placeholderProvider!),
        imageRamKey(tile.cacheKey, 225, 210),
      );
    });

    test('a larger variant is never held back by the floor', () {
      const String asset = '$_cdn/big.jpeg';
      final ImageVariant big = rung(asset, 900, 900);
      final ImageVariant want = rung(asset, 100, 100);
      variants
        ..record(asset, big)
        ..record(asset, want);
      seedRam(big);
      expect(decide(want).source, ImageLoadSource.variant);
    });
  });

  group('afterSeed', () {
    final ImageLoadDecision network = ImageLoadDecision.network(
      fadeIn: _fadeIn,
      fadeOut: _fadeOut,
    );
    const String key = '$_cdn/seeded.jpeg?w=225&h=225&fit=cover&format=webp';

    test('a network decision whose file the seed found → disk', () {
      expect(
        ImageLoadPolicy.afterSeed(network, key, diskIndex: disk),
        isNull,
        reason: 'not on disk: keep network',
      );
      disk.markDownloaded(key);
      final ImageLoadDecision? next = ImageLoadPolicy.afterSeed(
        network,
        key,
        diskIndex: disk,
      );
      expect(next, same(ImageLoadDecision.disk));
      expect(next!.fadeIn, Duration.zero);
      expect(next.shimmerDelay, ImageLoadPolicy.diskShimmerDelay);
      // The store's own metadata probe counts too.
      storeKeys.add('${key}x');
      expect(
        ImageLoadPolicy.afterSeed(network, '${key}x', diskIndex: disk),
        same(ImageLoadDecision.disk),
      );
    });

    test('only network → disk: other decisions stay', () {
      disk.markDownloaded(key);
      final ImageVariant small = _v('$_cdn/other.jpeg', 225);
      seedRam(small);
      for (final ImageLoadDecision d in <ImageLoadDecision>[
        ImageLoadDecision.ram,
        ImageLoadDecision.disk,
        ImageLoadDecision.variant(
          imageRamProvider(small.cacheKey, 225, 225),
          variantRamKey(small),
        ),
      ]) {
        expect(
          ImageLoadPolicy.afterSeed(d, key, diskIndex: disk),
          isNull,
          reason: '${d.source}',
        );
      }
    });
  });
}
