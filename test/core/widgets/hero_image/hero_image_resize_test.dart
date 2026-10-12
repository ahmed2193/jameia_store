// Locks what a size / URL change of a mounted HeroImage shows, and the
// cached-variant fidelity floor (ported from the reference's
// app_image_transition_test.dart (d), (d2), (e), (e3), (g)):
//   (d) a size change keeps the old pixels until the new size decodes —
//       same elements (the tile is keyed by its ASSET), no shimmer, no still
//       box; (d2) both sizes in RAM swap at once;
//   (e) smaller → larger: the cached smaller variant paints in the same box,
//       and (e3) its late frame shows the still box, never a hole;
//   (g) key changes while nothing landed remount instead of nesting octo's
//       gapless handlers, and a running shimmer stays running.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/media/image_ram_key.dart';
import 'package:hero_mart/src/core/media/image_variant_index.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_still_box.dart';
import 'package:hero_mart/src/core/widgets/hero_image_variant_placeholder.dart';
import 'package:hero_mart/src/core/widgets/hero_retrying_image.dart';

import 'hero_image_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpImagePipeline();
  final TestImages images = TestImages();

  testWidgets('(d) a size change keeps the old image until the new decodes', (
    t,
  ) async {
    const String raw = '$cdn/p2/swap.jpeg';
    final oldImg = await images.next(t);
    final newImg = await images.next(t);
    seedRam(urlFor(raw, 100), 225, oldImg);
    final pending = seedPending(urlFor(raw, 220), 467);

    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    expect(painted(t, oldImg), isTrue);
    final Element tile = t.element(find.byType(HeroRetryingImage));
    final Element cniElement = t.element(find.byType(CachedNetworkImage));

    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 220, height: 220)),
    );
    expect(cni(t).imageUrl, urlFor(raw, 220));
    expect(
      t.element(find.byType(HeroRetryingImage)),
      same(tile),
      reason: 'keyed by the asset, not the URL',
    );
    expect(
      t.element(find.byType(CachedNetworkImage)),
      same(cniElement),
      reason: 'updated in place (octo gapless path), not remounted',
    );
    expect(painted(t, oldImg), isTrue, reason: 'the old pixels stay');
    expect(find.byType(HeroImageShimmer), findsNothing);
    expect(find.byType(HeroImageStillBox), findsNothing);
    expect(
      cni(t).fadeInDuration,
      Duration.zero,
      reason: 'the old size is in RAM: a variant decision',
    );

    await t.pump(const Duration(seconds: 1));
    expect(painted(t, oldImg), isTrue, reason: 'still waiting for the decode');
    expect(find.byType(HeroImageShimmer), findsNothing);

    pending.complete(ImageInfo(image: newImg.clone()));
    await t.pump();
    await t.pump();
    expect(painted(t, newImg), isTrue);
    expect(painted(t, oldImg), isFalse, reason: 'replaced with no fade');
  });

  testWidgets('(d2) both sizes in RAM: the swap is immediate, no placeholder', (
    t,
  ) async {
    const String raw = '$cdn/p2/swap2.jpeg';
    final small = await images.next(t);
    final big = await images.next(t);
    seedRam(urlFor(raw, 100), 225, small);
    seedRam(urlFor(raw, 220), 467, big);
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 220, height: 220)),
    );
    expect(painted(t, big), isTrue);
    expect(painted(t, small), isFalse, reason: 'RAM decision: no crossfade');
    expect(find.byType(HeroImageShimmer), findsNothing);
    expect(find.byType(HeroImageStillBox), findsNothing);
  });

  testWidgets('(e) smaller → larger: the cached 225 paints in the 467 box', (
    t,
  ) async {
    const String raw = '$cdn/p2/grow.jpeg';
    final small = await images.next(t);
    final big = await images.next(t);
    final ImageVariant v225 = ImageVariant.of(
      canonicalImageUrl(raw),
      wireW: 225,
      wireH: 225,
      fit: 'cover',
      format: 'webp',
    );
    ImageVariantIndex.instance.record(v225.assetId, v225);
    seedRam(v225.cacheKey, 225, small);
    final pending = seedPending(urlFor(raw, 220), 467);

    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 220, height: 220)),
    );
    expect(cni(t).memCacheWidth, 467);
    final Finder placeholder = find.byType(HeroImageVariantPlaceholder);
    expect(placeholder, findsOneWidget);
    expect(painted(t, small), isTrue, reason: 'painted in the first frame');
    expect(t.getSize(placeholder), const Size(220, 220));
    expect(t.getSize(find.byType(HeroImage)), const Size(220, 220));
    expect(find.byType(HeroImageShimmer), findsNothing);
    expect(find.byType(HeroImageStillBox), findsNothing);
    expect(cni(t).fadeInDuration, Duration.zero);
    expect(cni(t).fadeOutDuration, Duration.zero);

    pending.complete(ImageInfo(image: big.clone()));
    await t.pump();
    await t.pump();
    expect(painted(t, big), isTrue);
    expect(find.byType(HeroImageVariantPlaceholder), findsNothing);
    expect(
      t.getSize(find.byType(HeroImage)),
      const Size(220, 220),
      reason: 'no layout shift',
    );
  });

  testWidgets('(e3) a variant whose frame is late shows the still box', (
    t,
  ) async {
    const String key = '$cdn/p2/late-variant.jpeg?w=225';
    final img = await images.next(t);
    final pending = seedPending(key, 225);
    await t.pumpWidget(
      host(
        HeroImageVariantPlaceholder(
          image: imageRamProvider(key, 225, 225),
          still: const HeroImageStillBox(),
          width: 100,
          height: 100,
        ),
      ),
    );
    expect(
      find.byType(HeroImageStillBox),
      findsOneWidget,
      reason: 'never a transparent box',
    );
    expect(t.getSize(find.byType(HeroImageStillBox)), const Size(100, 100));

    pending.complete(ImageInfo(image: img.clone()));
    await t.pump();
    await t.pump();
    expect(find.byType(HeroImageStillBox), findsNothing);
    expect(painted(t, img), isTrue);
  });

  testWidgets('(g) key changes with nothing landed remount, never nest', (
    t,
  ) async {
    const String raw = '$cdn/p2/hop.jpeg';
    HeroImageCacheManager.debugLoaderOverride = SilentLoader();
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    final Element first = t.element(find.byType(CachedNetworkImage));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(HeroImageShimmer), findsOneWidget);

    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 160, height: 160)),
    );
    expect(cni(t).imageUrl, urlFor(raw, 160));
    expect(urlFor(raw, 160), isNot(urlFor(raw, 100)));
    final Element second = t.element(find.byType(CachedNetworkImage));
    expect(second, isNot(same(first)), reason: 'nothing to keep: remount');
    expect(
      find.byType(Image),
      findsOneWidget,
      reason: 'no previous handler chained in as the placeholder',
    );
    // The tile was already shimmering: it stays live, no still box.
    expect(find.byType(HeroImageShimmer), findsOneWidget);
    expect(find.byType(HeroImageStillBox), findsNothing);

    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 220, height: 220)),
    );
    expect(t.element(find.byType(CachedNetworkImage)), isNot(same(second)));
    expect(cni(t).key, innerKey(0, epoch: 2));
    expect(find.byType(Image), findsOneWidget, reason: 'still one level');
    expect(find.byType(HeroImageShimmer), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('another asset on the same slot is a fresh tile', (t) async {
    HeroImageCacheManager.debugLoaderOverride = SilentLoader();
    await t.pumpWidget(
      host(const HeroImage(url: '$cdn/p2/one.jpeg', width: 100, height: 100)),
    );
    final Element tile = t.element(find.byType(HeroRetryingImage));
    await t.pumpWidget(
      host(const HeroImage(url: '$cdn/p2/two.jpeg', width: 100, height: 100)),
    );
    expect(t.element(find.byType(HeroRetryingImage)), isNot(same(tile)));
    expect(cni(t).key, innerKey(0), reason: 'a fresh state and decision');
    await t.pumpWidget(const SizedBox());
  });
}
