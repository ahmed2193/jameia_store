// The brand sheet kit (sign-in look): the grocery spread, its shared clock
// and recorded ring, the Hero lockup, the labeled field box and the sheet
// scaffold's rise / keyboard fold / reduced motion.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/grocery_doodles.dart';
import 'package:hero_mart/src/core/design/hero_mark_idle.dart';
import 'package:hero_mart/src/core/design/hero_mark.dart';
import 'package:hero_mart/src/core/design/hero_wordmark.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/brand_backdrop.dart';
import 'package:hero_mart/src/core/widgets/brand_backdrop_base_painter.dart';
import 'package:hero_mart/src/core/widgets/brand_backdrop_clock.dart';
import 'package:hero_mart/src/core/widgets/brand_backdrop_painter.dart';
import 'package:hero_mart/src/core/widgets/brand_backdrop_ring.dart';
import 'package:hero_mart/src/core/widgets/brand_sheet_fold.dart';
import 'package:hero_mart/src/core/widgets/brand_sheet_scaffold.dart';
import 'package:hero_mart/src/core/widgets/brand_sheet_scope.dart';
import 'package:hero_mart/src/core/widgets/hero_lockup.dart';
import 'package:hero_mart/src/core/widgets/hero_lockup_painter.dart';
import 'package:hero_mart/src/core/widgets/labeled_field_box.dart';

void main() {
  group('GroceryDoodlePainting', () {
    test('every doodle records without throwing', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final doodle in GroceryDoodle.values) {
        GroceryDoodlePainting.paint(canvas, doodle);
      }
      recorder.endRecording().dispose();
    });
  });

  group('BrandBackdropClock', () {
    test('counts running time once per frame and skips pauses', () {
      final start = BrandBackdropClock.elapsed;
      const t0 = Duration(seconds: 1000);
      BrandBackdropClock.advance(t0);
      final base = BrandBackdropClock.elapsed;
      expect(base - start, lessThanOrEqualTo(BrandBackdropClock.maxStep));

      const frame = Duration(milliseconds: 16);
      BrandBackdropClock.advance(t0 + frame);
      // A second backdrop ticking in the same frame moves nothing.
      BrandBackdropClock.advance(t0 + frame);
      expect(BrandBackdropClock.elapsed - base, frame);

      // A long gap (covered, paused) is skipped, not jumped over.
      BrandBackdropClock.advance(t0 + const Duration(seconds: 30));
      expect(BrandBackdropClock.elapsed - base, frame);
    });
  });

  group('BrandBackdropRing', () {
    test('records once per band size and frees the old picture', () {
      final ring = BrandBackdropRing();
      const band = Size(390, 220);
      final first = ring.pictureFor(band);
      expect(ring.pictureFor(band), same(first));
      final other = ring.pictureFor(const Size(800, 300));
      expect(other, isNot(same(first)));
      ring.dispose();
    });
  });

  group('HeroMarkIdle', () {
    test('the loop starts on the resting cape and a still bag', () {
      final rest = HeroMarkIdle.poseAt(0);
      expect(rest.phase, HeroMark.restPhase);
      expect(rest.wave, HeroMark.restWave);
      expect(rest.lift, 0);
    });
  });

  group('HeroLockupPainter.sizeFor', () {
    test('grows with the name and fits the mark over it', () {
      final small = HeroLockupPainter.sizeFor(30, HeroWordmark.latin);
      final large = HeroLockupPainter.sizeFor(44, HeroWordmark.latin);
      expect(large.width, greaterThan(small.width));
      expect(large.height, greaterThan(small.height));
      // The mark is twice the name's height, so the lockup is well taller.
      expect(small.height, greaterThan(30 * HeroLockupPainter.markToWord));
      final arabic = HeroLockupPainter.sizeFor(30, HeroWordmark.arabic);
      expect(arabic.height, greaterThan(0));
    });
  });

  Widget app(Widget child, {bool reduced = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(body: child),
      ),
    ),
  );

  group('LabeledFieldBox', () {
    testWidgets('shows its label and reports taps on the box', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          LabeledFieldBox(
            label: 'Phone number',
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      );
      expect(find.text('Phone number'), findsOneWidget);
      await tester.tap(find.byType(AnimatedContainer));
      expect(taps, 1);
    });
  });

  group('BrandBackdrop', () {
    const band = Rect.fromLTWH(0, 24, 390, 220);

    testWidgets('turns while animated, still under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(app(const BrandBackdrop(band: band)));
      await tester.pump(const Duration(milliseconds: 16));
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(
        app(const BrandBackdrop(band: band), reduced: true),
      );
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stops turning when told to (keyboard up)', (tester) async {
      await tester.pumpWidget(
        app(const BrandBackdrop(band: band, animate: false, reveal: false)),
      );
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('B1-02 turns for one ambient budget, then rests', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const BrandBackdrop(band: band, reveal: false)),
      );
      await tester.pump(AppMotion.ambientBudget - AppMotion.medium);
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

      await tester.pump(AppMotion.medium);
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('BX-02 the green is a still layer; only the spread repaints', (
      tester,
    ) async {
      await tester.pumpWidget(app(const BrandBackdrop(band: band)));
      CustomPaint layer<T>() => tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is T,
        ),
      );
      final base = layer<BrandBackdropBasePainter>();
      final spread = layer<BrandBackdropPainter>();
      // Each layer is the direct child of a repaint boundary of its own.
      for (final paint in [base, spread]) {
        final boundary = tester.widget<RepaintBoundary>(
          find
              .ancestor(
                of: find.byWidget(paint),
                matching: find.byType(RepaintBoundary),
              )
              .first,
        );
        expect(boundary.child, same(paint));
      }
      final still = base.painter! as BrandBackdropBasePainter;
      expect(
        still.shouldRepaint(const BrandBackdropBasePainter(band: band)),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('BrandSheetScaffold', () {
    const content = Key('sheet-content');

    Widget sheet({bool rise = true}) => BrandSheetScaffold(
      logoLabel: 'Hero',
      rise: rise,
      child: const Column(
        children: [
          BrandSheetFold(child: SizedBox(key: Key('fold'), height: 80)),
          SizedBox(key: content, height: 40),
        ],
      ),
    );

    testWidgets('the sheet rises into place with its content', (tester) async {
      await tester.pumpWidget(app(sheet()));
      final start = tester.getTopLeft(find.byKey(content)).dy;
      await tester.pump(
        BrandSheetScaffold.riseDelay + BrandSheetScaffold.riseDuration,
      );
      final rested = tester.getTopLeft(find.byKey(content)).dy;
      expect(rested, lessThan(start));
      expect(find.byType(HeroLockup), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the keyboard folds the header and what folds with it', (
      tester,
    ) async {
      await tester.pumpWidget(app(sheet(rise: false)));
      await tester.pump();
      final open = tester.getTopLeft(find.byKey(content)).dy;
      final scope = tester.widget<BrandSheetScope>(
        find.byType(BrandSheetScope),
      );
      expect(scope.fold.value, 0);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(scope.fold.value, 1);
      expect(tester.getSize(find.byKey(const Key('fold'))).height, 80);
      expect(tester.getSize(find.byType(BrandSheetFold)).height, lessThan(1));
      expect(tester.getTopLeft(find.byKey(content)).dy, lessThan(open));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reduced motion: in place at once', (tester) async {
      await tester.pumpWidget(app(sheet(), reduced: true));
      await tester.pump();
      final placed = tester.getTopLeft(find.byKey(content)).dy;
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getTopLeft(find.byKey(content)).dy, placed);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
