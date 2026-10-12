// Locks HeroImage's retry machine (ported from the reference's
// app_image_transition_test.dart (e2), (f), (f2), (f3), plus the
// transform-broken registry and Hero's reconnect hook):
//   (e2) a failing tile keeps its cached variant while it retries;
//   (f)  a failing load retries behind the shimmer on its backoff (the
//        first failure hops to the raw URL at once), and a new URL resets
//        the machine;
//   (f2) a stalled body (ImageBodyStalledException) retries the SAME
//        variant on the backoff: no raw hop, no registry entry;
//   (f3) a header timeout still hops to the raw URL at once, no verdict;
//   (f4) a server reject (4xx/5xx) marks the asset transform-broken: every
//        size of it goes raw;
//   (r)  HeroImage.retryAllPendingImages (app.dart's reconnect listener)
//        collapses a pending backoff into an immediate retry.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/media/image_variant_index.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_still_box.dart';
import 'package:hero_mart/src/core/widgets/hero_image_variant_placeholder.dart';
import 'package:http/http.dart' as http;

import 'hero_image_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpImagePipeline();
  final TestImages images = TestImages();

  /// Lets a failure reach the error builder, its post-frame hop and the
  /// awaited eviction of the next attempt.
  Future<void> settleFailure(WidgetTester t) async {
    for (int i = 0; i < 6; i++) {
      await t.pump();
    }
  }

  testWidgets('(e2) a failing tile keeps the cached variant while it retries', (
    t,
  ) async {
    const String raw = '$cdn/p2/flaky.jpeg';
    final small = await images.next(t);
    final ImageVariant v225 = ImageVariant.of(
      canonicalImageUrl(raw),
      wireW: 225,
      wireH: 225,
      fit: 'cover',
      format: 'webp',
    );
    ImageVariantIndex.instance.record(v225.assetId, v225);
    seedRam(v225.cacheKey, 225, small);
    final FailingLoader loader = FailingLoader();
    HeroImageCacheManager.debugLoaderOverride = loader;
    final String want = urlFor(raw, 220);

    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 220, height: 220)),
    );
    expect(find.byType(HeroImageVariantPlaceholder), findsOneWidget);

    // Attempt 0 fails → immediate raw fallback (attempt 1), which fails too.
    await settleFailure(t);
    expect(cni(t).key, innerKey(1, raw: true));
    expect(loader.urls, <String>[want, canonicalImageUrl(raw)]);
    expect(
      find.byType(HeroImageVariantPlaceholder),
      findsOneWidget,
      reason: 'attempt 1 still paints the cached size',
    );
    expect(painted(t, small), isTrue);
    expect(find.byType(HeroImageShimmer), findsNothing);

    // The backoff still runs underneath: 1 s ± 25 % to attempt 2.
    await t.pump(const Duration(milliseconds: 1260));
    await t.pump();
    await t.pump();
    expect(cni(t).key, innerKey(2, raw: true));
    expect(loader.urls, hasLength(3));
    expect(find.byType(HeroImageVariantPlaceholder), findsOneWidget);

    // Once the cached size is gone from RAM, the next attempt shimmers.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await t.pump(const Duration(milliseconds: 2600));
    await t.pump();
    await t.pump();
    expect(cni(t).key, innerKey(3, raw: true));
    expect(find.byType(HeroImageVariantPlaceholder), findsNothing);
    expect(find.byType(HeroImageShimmer), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    '(f) a failing load retries behind the shimmer with its backoff',
    (t) async {
      const String raw = '$cdn/p2/fail.jpeg';
      final FailingLoader loader = FailingLoader(
        const SocketException('Connection reset by peer'),
      );
      HeroImageCacheManager.debugLoaderOverride = loader;
      await t.pumpWidget(
        host(const HeroImage(url: raw, width: 100, height: 100)),
      );
      expect(
        find.byType(HeroImageStillBox),
        findsOneWidget,
        reason: 'attempt 0',
      );

      // Attempt 0 fails → the shimmer → an immediate switch to the raw
      // fallback (attempt 1), which fails too.
      await settleFailure(t);
      expect(cni(t).key, innerKey(1, raw: true));
      expect(cni(t).imageUrl, canonicalImageUrl(raw));
      expect(
        cni(t).fadeInDuration,
        AppMotion.fast,
        reason: 'a retry is a network load',
      );
      expect(find.byType(HeroImageShimmer), findsOneWidget);
      expect(find.byType(HeroImageStillBox), findsNothing);
      expect(loader.urls, <String>[urlFor(raw, 100), canonicalImageUrl(raw)]);
      expect(
        ImageDiskIndex.instance.contains(urlFor(raw, 100)),
        isFalse,
        reason: 'nothing landed yet',
      );

      // Backoff after attempt 1: 1 s ± 25 % before attempt 2, never sooner.
      await t.pump(const Duration(milliseconds: 740));
      expect(cni(t).key, innerKey(1, raw: true));
      await t.pump(const Duration(milliseconds: 520));
      await t.pump();
      await t.pump();
      expect(cni(t).key, innerKey(2, raw: true));
      expect(loader.urls, hasLength(3));
      expect(find.byType(HeroImageShimmer), findsOneWidget);

      // A new URL on the same tile resets the machine: attempt 0, the primary
      // URL (and, since the failed image never landed, a fresh octo: epoch 1).
      await t.pumpWidget(
        host(const HeroImage(url: raw, width: 220, height: 220)),
      );
      expect(cni(t).key, innerKey(0, epoch: 1));
      expect(cni(t).imageUrl, urlFor(raw, 220));
      expect(
        urlFor(raw, 220),
        isNot(canonicalImageUrl(raw)),
        reason: 'a variant',
      );
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('(f2) a stalled body retries the SAME variant, no raw hop', (
    t,
  ) async {
    const String raw = '$cdn/p2/stall.jpeg';
    final String want = urlFor(raw, 100);
    final FailingLoader loader = FailingLoader(
      ImageBodyStalledException('Image body stalled for 15s', Uri.parse(want)),
    );
    HeroImageCacheManager.debugLoaderOverride = loader;
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );

    // Attempt 0 stalls: no immediate switch to the raw URL.
    await settleFailure(t);
    expect(cni(t).key, innerKey(0));
    expect(loader.urls, <String>[want]);
    expect(find.byType(HeroImageShimmer), findsOneWidget);

    // The first backoff step (500 ms ± 25 %), then attempt 1 on the variant.
    await t.pump(const Duration(milliseconds: 370));
    expect(cni(t).key, innerKey(0), reason: 'never sooner than the backoff');
    await t.pump(const Duration(milliseconds: 260));
    await t.pump();
    await t.pump();
    expect(cni(t).key, innerKey(1), reason: 'attempt 1, not on the fallback');
    expect(cni(t).imageUrl, want);
    expect(loader.urls, <String>[want, want]);

    // The next step (1 s ± 25 %): attempt 2, still the variant.
    await t.pump(const Duration(milliseconds: 1260));
    await t.pump();
    await t.pump();
    expect(cni(t).key, innerKey(2));
    expect(cni(t).imageUrl, want);
    expect(loader.urls, <String>[want, want, want]);
    expect(urlFor(raw, 100), want, reason: 'no transform-broken verdict');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(f3) a header timeout still hops to the raw URL at once', (
    t,
  ) async {
    const String raw = '$cdn/p2/timeout.jpeg';
    final String want = urlFor(raw, 100);
    final FailingLoader loader = FailingLoader(
      http.ClientException(
        'Image download timed out after 25s',
        Uri.parse(want),
      ),
    );
    HeroImageCacheManager.debugLoaderOverride = loader;
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );

    await settleFailure(t);
    expect(cni(t).key, innerKey(1, raw: true));
    expect(cni(t).imageUrl, canonicalImageUrl(raw));
    expect(loader.urls, <String>[want, canonicalImageUrl(raw)]);
    expect(
      urlFor(raw, 100),
      want,
      reason: 'a timeout publishes no transform-broken verdict',
    );
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(f4) a CDN 500 marks the asset: every size of it goes raw', (
    t,
  ) async {
    const String raw = '$cdn/p2/exif.jpeg';
    final String want = urlFor(raw, 100);
    final FailingLoader loader = FailingLoader(); // HttpExceptionWithStatus 500
    HeroImageCacheManager.debugLoaderOverride = loader;
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );

    await settleFailure(t);
    expect(cni(t).key, innerKey(1, raw: true));
    expect(loader.urls, <String>[want, canonicalImageUrl(raw)]);
    // The raw bytes are expected under the variant's key.
    ImageDiskIndex.instance.markDownloaded(canonicalImageUrl(raw));
    expect(ImageDiskIndex.instance.contains(want), isTrue);
    // The verdict: this asset skips the transform at every size and site.
    expect(urlFor(raw, 100), canonicalImageUrl(raw));
    expect(urlFor(raw, 220), canonicalImageUrl(raw));
    expect(urlFor('$cdn/p2/healthy.jpeg', 100), contains('format=webp'));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(r) retryAllPendingImages retries a backed-off tile now', (
    t,
  ) async {
    const String raw = '$cdn/p2/reconnect.jpeg';
    final FailingLoader loader = FailingLoader(
      const SocketException('Network is unreachable'),
    );
    HeroImageCacheManager.debugLoaderOverride = loader;
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    await settleFailure(t);
    expect(cni(t).key, innerKey(1, raw: true));
    expect(loader.urls, hasLength(2));

    // Attempt 1 failed: its backoff (1 s ± 25 %) is pending. The network
    // comes back long before it.
    await t.pump(const Duration(milliseconds: 100));
    expect(cni(t).key, innerKey(1, raw: true));
    HeroImage.retryAllPendingImages();
    await t.pump();
    await t.pump();
    expect(cni(t).key, innerKey(2, raw: true), reason: 'retried at once');
    expect(loader.urls, hasLength(3));
    await t.pumpWidget(const SizedBox());
  });
}
