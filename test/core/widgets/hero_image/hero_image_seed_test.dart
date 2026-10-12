// Locks the late disk-index seed (ported from the reference's
// app_image_transition_test.dart (h)–(h3); its FINAL_REPORT S7 cold start):
// a tile that mounted `network` before the seed landed turns `disk` in place
// once it does — no shimmer, no fade, same elements, the `[IMGCACHE]` trace
// says so — while a seed without its key leaves it network, and a seed after
// the shimmer started keeps the sweep going.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/media/image_load_trace.dart';
import 'package:hero_mart/src/core/media/media_log.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_delayed_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_still_box.dart';

import 'hero_image_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpImagePipeline();

  testWidgets('(h) the seed lands after a network mount: the tile turns disk', (
    t,
  ) async {
    const String raw = '$cdn/p2/coldseed.jpeg';
    final String key = urlFor(raw, 100);
    HeroImageCacheManager.debugLoaderOverride = SilentLoader();
    final List<String> logs = <String>[];
    final bool Function(String) originalHint = ImageLoadTrace.diskHint;
    final Future<DateTime?> Function(String) originalLookup =
        ImageLoadTrace.diskLookup;
    ImageLoadTrace.diskHint = (_) => false;
    ImageLoadTrace.diskLookup = (_) async => null;
    ImageLoadTrace.enabled = true;
    ImageLoadTrace.reset();
    MediaLog.debugSink = (String name, String m) =>
        logs.add(MediaLog.format(name, m));
    try {
      await t.pumpWidget(
        host(const HeroImage(url: raw, width: 100, height: 100)),
      );
      expect(
        cni(t).fadeInDuration,
        AppMotion.fast,
        reason: 'decided network: the seed had not landed',
      );
      final Element image = t.element(find.byType(CachedNetworkImage));
      final Element quiet = t.element(find.byType(HeroImageDelayedShimmer));
      await t.pump(const Duration(milliseconds: 200));

      expect(
        await ImageDiskIndex.instance.seedKeys(() async => <String>[key]),
        1,
      );
      await t.pump();

      expect(cni(t).fadeInDuration, Duration.zero);
      expect(cni(t).fadeOutDuration, Duration.zero);
      expect(
        t.element(find.byType(CachedNetworkImage)),
        same(image),
        reason: 'not remounted',
      );
      expect(
        t.element(find.byType(HeroImageDelayedShimmer)),
        same(quiet),
        reason: 'one placeholder shape throughout',
      );
      expect(find.byType(HeroImageStillBox), findsOneWidget);

      // Past the network delay: no shimmer. The disk safety net counts 1 s
      // from the SAME wait start, not from the re-decision.
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(HeroImageShimmer), findsNothing);
      await t.pump(const Duration(milliseconds: 499));
      expect(find.byType(HeroImageShimmer), findsNothing);
      await t.pump(const Duration(milliseconds: 2));
      expect(
        find.byType(HeroImageShimmer),
        findsOneWidget,
        reason: 'the 1 s disk safety net',
      );

      final List<String> mine = logs
          .where((String l) => l.contains('coldseed'))
          .toList();
      expect(
        mine.where((String l) => l.contains('] build ')).single,
        contains('policy=network'),
      );
      expect(
        mine.where((String l) => l.contains('] redecide ')).single,
        contains('policy=disk from=network cause=seed'),
      );
      final Map<String, Object> s = ImageLoadTrace.snapshot();
      expect(s['policy.disk'], 1);
      expect(s['policy.network'] ?? 0, 0);
      expect(s['placeholder_disk'], 1);
      expect(s['shimmer'] ?? 0, 0);
      expect(s['redecide'], 1);
    } finally {
      MediaLog.debugSink = null;
      ImageLoadTrace.enabled = false;
      ImageLoadTrace.diskHint = originalHint;
      ImageLoadTrace.diskLookup = originalLookup;
    }
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(h2) a seed without the tile key leaves it network', (t) async {
    const String raw = '$cdn/p2/coldmiss.jpeg';
    HeroImageCacheManager.debugLoaderOverride = SilentLoader();
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    await t.pump(const Duration(milliseconds: 100));
    await ImageDiskIndex.instance.seedKeys(
      () async => <String>['$cdn/p2/other.jpeg'],
    );
    await t.pump();

    expect(ImageDiskIndex.instance.seeded.value, isTrue);
    expect(cni(t).fadeInDuration, AppMotion.fast);
    await t.pump(const Duration(milliseconds: 201));
    expect(
      find.byType(HeroImageShimmer),
      findsOneWidget,
      reason: 'the network shimmer at 300 ms, as before',
    );
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    '(h3) a seed after the shimmer started: disk, sweep keeps going',
    (t) async {
      const String raw = '$cdn/p2/coldlate.jpeg';
      HeroImageCacheManager.debugLoaderOverride = SilentLoader();
      await t.pumpWidget(
        host(const HeroImage(url: raw, width: 100, height: 100)),
      );
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(HeroImageShimmer), findsOneWidget);
      final Element quiet = t.element(find.byType(HeroImageDelayedShimmer));

      await ImageDiskIndex.instance.seedKeys(
        () async => <String>[urlFor(raw, 100)],
      );
      await t.pump();

      expect(cni(t).fadeInDuration, Duration.zero, reason: 'disk: no fade');
      expect(t.element(find.byType(HeroImageDelayedShimmer)), same(quiet));
      expect(
        find.byType(HeroImageShimmer),
        findsOneWidget,
        reason: 'a running sweep never snaps back to the still box',
      );
      expect(find.byType(HeroImageStillBox), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
}
