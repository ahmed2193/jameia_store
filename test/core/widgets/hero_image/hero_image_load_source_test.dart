// Locks HeroImage's load-source transitions (ported from the reference's
// app_image_transition_test.dart (a)–(c2b); docs/image_pipeline.md):
//   (a) RAM hit: first frame painted, no placeholder at all;
//   (b) disk-known: the still box (no shimmer) and zero fades;
//   (c) unknown: the still box, the shimmer after 300 ms, Hero's fast fades
//       — and a load landing after the shimmer started crossfades from the
//       LIVE shimmer (octo remounts the placeholder; the deadline is the
//       tile's), while one landing before it never starts a sweep;
//   reduced motion: the network fades are cut.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_delayed_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_still_box.dart';

import 'hero_image_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpImagePipeline();
  final TestImages images = TestImages();

  testWidgets('(a) RAM hit: painted in the first frame, no placeholder', (
    t,
  ) async {
    const String raw = '$cdn/p2/ram.jpeg';
    final img = await images.next(t);
    seedRam(urlFor(raw, 100), 225, img);
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    expect(painted(t, img), isTrue);
    expect(find.byType(HeroImageStillBox), findsNothing);
    expect(find.byType(HeroImageDelayedShimmer), findsNothing);
    expect(find.byType(HeroImageShimmer), findsNothing);
    expect(
      ImageDiskIndex.instance.contains(urlFor(raw, 100)),
      isTrue,
      reason: 'a RAM hit tells the disk index',
    );
  });

  testWidgets('(b) disk-known: a still box, no shimmer, zero fades', (t) async {
    const String raw = '$cdn/p2/disk.jpeg';
    ImageDiskIndex.instance.markDownloaded(urlFor(raw, 100));
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );

    expect(find.byType(HeroImageStillBox), findsOneWidget);
    expect(find.byType(HeroImageShimmer), findsNothing);
    expect(t.getSize(find.byType(HeroImageStillBox)), const Size(100, 100));
    expect(cni(t).fadeInDuration, Duration.zero);
    expect(cni(t).fadeOutDuration, Duration.zero);
    // A disk decode lands in frames; past the network delay there is still
    // no shimmer (the disk safety net is 1 s).
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(HeroImageShimmer), findsNothing);
    expect(find.byType(HeroImageStillBox), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(c) unknown: still box, shimmer after 300 ms, fast fades', (
    t,
  ) async {
    const String raw = '$cdn/p2/net.jpeg';
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );

    expect(find.byType(HeroImageDelayedShimmer), findsOneWidget);
    expect(find.byType(HeroImageStillBox), findsOneWidget);
    expect(find.byType(HeroImageShimmer), findsNothing);
    expect(cni(t).fadeInDuration, AppMotion.fast);
    expect(cni(t).fadeOutDuration, AppMotion.fast);

    await t.pump(const Duration(milliseconds: 299));
    expect(find.byType(HeroImageShimmer), findsNothing);
    await t.pump(const Duration(milliseconds: 2));
    expect(find.byType(HeroImageShimmer), findsOneWidget);
    expect(find.byType(HeroImageStillBox), findsNothing);
    expect(
      find.byType(HeroImageDelayedShimmer),
      findsOneWidget,
      reason: 'one shape',
    );
    expect(t.getSize(find.byType(HeroImageShimmer)), const Size(100, 100));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(c2) landing at 400 ms crossfades from the LIVE shimmer', (
    t,
  ) async {
    const String raw = '$cdn/p2/late.jpeg';
    final img = await images.next(t);
    final pending = seedPending(urlFor(raw, 100), 225);
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(HeroImageShimmer), findsOneWidget);
    final running = t.element(find.byType(HeroImageDelayedShimmer));

    pending.complete(ImageInfo(image: img.clone()));
    await t.pump();
    await t.pump();
    expect(painted(t, img), isTrue);
    // octo_image's fade stack remounts the placeholder...
    expect(
      t.element(find.byType(HeroImageDelayedShimmer)),
      isNot(same(running)),
      reason: 'remounted inside the fade-out stack',
    );
    // ...which is still the running shimmer, not the still box.
    expect(find.byType(HeroImageShimmer), findsOneWidget);
    expect(find.byType(HeroImageStillBox), findsNothing);

    await t.pump(AppMotion.fast + const Duration(milliseconds: 20));
    expect(find.byType(HeroImageShimmer), findsNothing, reason: 'faded out');
    expect(painted(t, img), isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(c2b) landing at 200 ms: the fade-out underlay never shimmers', (
    t,
  ) async {
    const String raw = '$cdn/p2/early.jpeg';
    final img = await images.next(t);
    final pending = seedPending(urlFor(raw, 100), 225);
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100)),
    );
    await t.pump(const Duration(milliseconds: 200));
    expect(find.byType(HeroImageDelayedShimmer), findsOneWidget);
    expect(find.byType(HeroImageStillBox), findsOneWidget);
    expect(find.byType(HeroImageShimmer), findsNothing);

    pending.complete(ImageInfo(image: img.clone()));
    await t.pump();
    await t.pump();
    expect(painted(t, img), isTrue);
    // octo remounts the placeholder as the fade-out underlay with 100 ms of
    // the deadline left, but the image is already here: the plain still box,
    // no delayed shimmer and no timer to turn into a sweep.
    expect(
      find.byType(HeroImageStillBox),
      findsOneWidget,
      reason: 'the underlay beneath the image',
    );
    expect(find.byType(HeroImageDelayedShimmer), findsNothing);
    expect(find.byType(HeroImageShimmer), findsNothing);

    // Through the 300 ms deadline and the rest of the fade-out.
    const Duration step = Duration(milliseconds: 20);
    for (int ms = 20; ms <= AppMotion.fast.inMilliseconds; ms += 20) {
      await t.pump(step);
      expect(
        find.byType(HeroImageShimmer),
        findsNothing,
        reason: 'no sweep at +$ms ms of the fade-out',
      );
      expect(
        find.byType(HeroImageDelayedShimmer),
        findsNothing,
        reason: 'at +$ms ms',
      );
    }
    await t.pump(step);
    expect(find.byType(HeroImageStillBox), findsNothing, reason: 'faded out');
    expect(painted(t, img), isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion: a network load cuts in, no fade', (t) async {
    const String raw = '$cdn/p2/reduced.jpeg';
    await t.pumpWidget(
      host(const HeroImage(url: raw, width: 100, height: 100), reduced: true),
    );
    expect(cni(t).fadeInDuration, Duration.zero);
    expect(cni(t).fadeOutDuration, Duration.zero);
    expect(find.byType(HeroImageStillBox), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
