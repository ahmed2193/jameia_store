// Locks where the shimmer delay counts from (ported from the reference's
// app_image_transition_test.dart (c3)–(c6); its FINAL_REPORT §8 "S7 cold
// start"): the FIRST FRAME that paints the placeholder (the tile's
// ImagePlaceholderAnchor), not the mount. A cold start whose first frame
// lands 1.5 s after the tiles mounted still shows the still box, and the
// shimmer only comes a full delay after that frame. `pumpWidget(duration:)`
// cannot separate mount from first frame, so SlowFrame burns the time inside
// the frame's paint (elapseBlocking).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_disk_index.dart';
import 'package:hero_mart/src/core/media/image_placeholder_anchor.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_delayed_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_shimmer.dart';
import 'package:hero_mart/src/core/widgets/hero_image_still_box.dart';

import 'hero_image_test_support.dart';

const ValueKey<String> _still = ValueKey<String>('still');
const ValueKey<String> _live = ValueKey<String>('live');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpImagePipeline();

  /// Every Timer created while [body] runs, by duration.
  Future<void> recordTimers(
    List<Duration> into,
    Future<void> Function() body,
  ) => runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, d, f) {
        into.add(d);
        return parent.createTimer(zone, d, f);
      },
    ),
  );

  testWidgets(
    '(c3) the delay starts at its first frame; an anchor with no time left '
    'is live at once, no Timer',
    (t) async {
      final List<Duration> timers = <Duration>[];
      // [ago]: an anchor set that long ago (a remount of a waiting tile).
      Future<void> mount(Duration delay, {Duration? ago}) => recordTimers(
        timers,
        () => t.pumpWidget(
          HeroImageDelayedShimmer(
            key: UniqueKey(),
            delay: delay,
            anchor: ago == null
                ? null
                : (ImagePlaceholderAnchor()
                    ..atUs = ImagePlaceholderClock.nowUs - ago.inMicroseconds),
            still: const SizedBox(key: _still),
            shimmer: (_) => const SizedBox(key: _live),
          ),
        ),
      );

      for (final Duration ago in <Duration>[
        const Duration(milliseconds: 300),
        const Duration(milliseconds: 900),
      ]) {
        await mount(const Duration(milliseconds: 300), ago: ago);
        expect(find.byKey(_live), findsOneWidget);
        expect(find.byKey(_still), findsNothing);
        expect(timers, isEmpty, reason: 'no timer after $ago');
      }

      // No delay at all: live once the first frame has anchored it.
      await mount(Duration.zero);
      await t.pump();
      expect(find.byKey(_live), findsOneWidget);
      expect(timers, isEmpty, reason: 'a zero delay arms nothing');

      // Time left on a handed-in anchor: the still child and exactly that.
      await mount(
        const Duration(milliseconds: 120),
        ago: const Duration(milliseconds: 50),
      );
      expect(find.byKey(_still), findsOneWidget);
      expect(timers, <Duration>[const Duration(milliseconds: 70)]);
      await t.pump(const Duration(milliseconds: 70));
      expect(find.byKey(_live), findsOneWidget);
      timers.clear();

      // No anchor yet: still, and the timer is the FULL delay from the frame.
      await mount(const Duration(milliseconds: 120));
      expect(find.byKey(_still), findsOneWidget);
      expect(timers, <Duration>[const Duration(milliseconds: 120)]);
      await t.pump(const Duration(milliseconds: 119));
      expect(find.byKey(_still), findsOneWidget);
      await t.pump(const Duration(milliseconds: 1));
      expect(find.byKey(_live), findsOneWidget);
    },
  );

  testWidgets(
    '(c4) a rebuild with the same delay re-arms nothing; a changed one '
    're-arms on what is left of it from the same anchor',
    (t) async {
      final List<Duration> timers = <Duration>[];
      Future<void> build(Duration delay) => recordTimers(
        timers,
        () => t.pumpWidget(
          HeroImageDelayedShimmer(
            key: const ValueKey<String>('tile'),
            delay: delay,
            still: const SizedBox(key: _still),
            shimmer: (_) => const SizedBox(key: _live),
          ),
        ),
      );

      // Anchored at this first frame (t = 0).
      await build(const Duration(milliseconds: 300));
      expect(timers, <Duration>[const Duration(milliseconds: 300)]);
      final Element element = t.element(find.byType(HeroImageDelayedShimmer));

      // Rebuilds 100 ms and 200 ms in: an equal (not identical) delay, the
      // same timer.
      for (int i = 0; i < 2; i++) {
        await t.pump(const Duration(milliseconds: 100));
        await build(const Duration(milliseconds: 150) * 2);
      }
      expect(t.element(find.byType(HeroImageDelayedShimmer)), same(element));
      expect(timers, hasLength(1), reason: 'no timer per rebuild');
      expect(find.byKey(_still), findsOneWidget);

      // A re-decision (a longer delay, 500 ms from the same anchor) re-arms
      // on what is left of it: 300 ms at t = 200.
      await build(const Duration(milliseconds: 500));
      expect(timers, hasLength(2));
      expect(timers.last, const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 299));
      expect(
        find.byKey(_still),
        findsOneWidget,
        reason: 'the original 300 ms no longer fires',
      );
      await t.pump(const Duration(milliseconds: 1));
      expect(find.byKey(_live), findsOneWidget);

      // Live stays live: a changed delay never snaps a running sweep back.
      await build(const Duration(milliseconds: 900));
      expect(find.byKey(_live), findsOneWidget);
      expect(timers, hasLength(2));
    },
  );

  testWidgets(
    '(c5) disk-known tile, first frame 1.5 s after mount: still box, and '
    'the 1 s net counts from that frame',
    (t) async {
      // Cold start: the first-screen tiles mount, then the first frame lands
      // over a second later. A deadline counted from mount would be spent
      // before anything was painted, and a shimmer would sweep over a decode
      // that lands a few frames on.
      const String raw = '$cdn/p2/latefirst.jpeg';
      ImageDiskIndex.instance.markDownloaded(urlFor(raw, 100));
      HeroImageCacheManager.debugLoaderOverride = SilentLoader();

      // The tile mounts (and decides) at t = 0; the first frame ends at
      // t = 1.5 s. Timers armed at mount are overdue by then.
      await t.pumpWidget(
        slowFrameHost(
          const HeroImage(url: raw, width: 100, height: 100),
          const Duration(milliseconds: 1500),
        ),
      );
      await t.pump(Duration.zero);
      expect(cni(t).fadeInDuration, Duration.zero, reason: 'decided disk');
      expect(find.byType(HeroImageDelayedShimmer), findsOneWidget);
      expect(
        find.byType(HeroImageStillBox),
        findsOneWidget,
        reason: 'the still box in the first frame',
      );
      expect(
        find.byType(HeroImageShimmer),
        findsNothing,
        reason: 'no sweep over a decode a few frames away',
      );

      // The safety net: 1 s after that frame, and not a tick before.
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 499));
      expect(find.byType(HeroImageShimmer), findsNothing);
      expect(find.byType(HeroImageStillBox), findsOneWidget);
      await t.pump(const Duration(milliseconds: 2));
      expect(
        find.byType(HeroImageShimmer),
        findsOneWidget,
        reason: 'nothing landed: the 1 s net, from the first frame',
      );
      expect(find.byType(HeroImageStillBox), findsNothing);
      expect(
        find.byType(HeroImageDelayedShimmer),
        findsOneWidget,
        reason: 'one shape',
      );
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    '(c6) network tile, first frame ending 500 ms after mount: its 300 ms '
    'count from that frame',
    (t) async {
      const String raw = '$cdn/p2/latenet.jpeg';
      HeroImageCacheManager.debugLoaderOverride = SilentLoader();
      await t.pumpWidget(
        slowFrameHost(
          const HeroImage(url: raw, width: 100, height: 100),
          const Duration(milliseconds: 500),
        ),
      );
      await t.pump(Duration.zero);
      expect(cni(t).fadeInDuration, AppMotion.fast, reason: 'network');
      expect(find.byType(HeroImageStillBox), findsOneWidget);
      expect(find.byType(HeroImageShimmer), findsNothing);

      await t.pump(const Duration(milliseconds: 299));
      expect(find.byType(HeroImageShimmer), findsNothing);
      await t.pump(const Duration(milliseconds: 2));
      expect(find.byType(HeroImageShimmer), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
}
