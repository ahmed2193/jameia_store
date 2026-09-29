// The category shelf moves by itself: its tiles cascade in, their washes
// drift, and a shelf longer than the screen glides to its end and back —
// but never under a finger, off screen, under reduced motion or with a
// screen reader on.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade_item.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_category_aurora_painter.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_category_entrance.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_category_grid.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_category_tile.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_tile_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two rows of 15 columns: wider than the 800-wide test screen.
const int _long = 30;

/// Room under the shelf, enough to scroll it off the 600-high test screen.
const double _below = 2000;

const Duration _frame = Duration(milliseconds: 16);

HomeCategoryRailSection _shelf(int count) => HomeCategoryRailSection(
  id: 'cat',
  title: 'Shop by category',
  categories: [
    for (var i = 0; i < count; i++)
      CatalogCategoryEntity(id: 'c$i', slug: 'c$i', name: 'Category $i'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  /// The shelf as the feed shows it: a block of the feed's first-load
  /// cascade, whose arrival runs the tiles' entrance.
  Future<void> pumpShelf(
    WidgetTester tester, {
    int count = _long,
    bool reducedMotion = false,
    bool screenReader = false,
    ScrollController? page,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
              accessibleNavigation: screenReader,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                controller: page,
                child: Column(
                  children: [
                    EntranceCascade(
                      child: EntranceCascadeItem(
                        index: 0,
                        child: HomeCategoryGrid(
                          section: _shelf(count),
                          onOpenCategory: (_) {},
                          onViewAll: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: _below),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The block starts its entrance on the next frame.
    await tester.pump();
  }

  ScrollPosition shelfOf(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  /// How far into its entrance the tile at [index] is (0 hidden, 1 shown).
  double entranceOf(WidgetTester tester, int index) => tester
      .widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(HomeCategoryEntrance).at(index),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  Duration glideTime(double distance) => Duration(
    milliseconds:
        (distance /
                HomeCategoryGrid.glideSpeed *
                Duration.millisecondsPerSecond)
            .ceil(),
  );

  group('the glide', () {
    testWidgets('a long shelf rests first, then glides at its speed', (
      tester,
    ) async {
      await pumpShelf(tester);
      final shelf = shelfOf(tester);
      expect(shelf.maxScrollExtent, greaterThan(0));

      await tester.pump(const Duration(seconds: 2));
      expect(shelf.pixels, 0, reason: 'still resting');

      // The rest is over: the glide's first frame, then a second of it.
      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, closeTo(HomeCategoryGrid.glideSpeed, 1));
    });

    testWidgets('BX-03 it glides in bursts of one ambient budget with a rest '
        'between; at the end it rests, then glides back', (tester) async {
      await pumpShelf(tester);
      final shelf = shelfOf(tester);
      final end = shelf.maxScrollExtent;
      expect(end, greaterThan(HomeCategoryGrid.burstReach));

      await tester.pump(AppMotion.carousel);
      await tester.pump(AppMotion.ambientBudget);
      // An animation is over on the first frame past its duration.
      await tester.pump(_frame);
      expect(shelf.pixels, closeTo(HomeCategoryGrid.burstReach, 1));

      // The rest: nothing moves and nothing ticks.
      final rested = shelf.pixels;
      await tester.pump(AppMotion.carousel ~/ 2);
      expect(shelf.pixels, rested);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Burst after burst, to the end.
      for (var burst = 0; burst < 20 && shelf.pixels < end; burst++) {
        await tester.pump(AppMotion.carousel);
        await tester.pump(AppMotion.ambientBudget);
        await tester.pump(_frame);
      }
      expect(shelf.pixels, end);
      expect(glideTime(end), greaterThan(AppMotion.ambientBudget));

      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, closeTo(end - HomeCategoryGrid.glideSpeed, 1));
    });

    testWidgets('BX-03 a drag holds the shelf until its scroll settles, then '
        'a full rest', (tester) async {
      await pumpShelf(tester);
      final shelf = shelfOf(tester);
      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, greaterThan(0), reason: 'gliding');

      await tester.fling(find.byType(GridView), const Offset(-120, 0), 800);
      await tester.pumpAndSettle();
      final settled = shelf.pixels;
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'the wash stopped with the glide',
      );

      await tester.pump(AppMotion.carousel - const Duration(milliseconds: 100));
      expect(shelf.pixels, settled, reason: 'resting after the scroll');

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, isNot(settled));
    });

    testWidgets('a finger holds the shelf; it picks up again after a rest', (
      tester,
    ) async {
      await pumpShelf(tester);
      final shelf = shelfOf(tester);
      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      final held = shelf.pixels;
      expect(held, greaterThan(0));

      final finger = await tester.startGesture(
        tester.getCenter(find.byType(GridView)),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(shelf.pixels, held, reason: 'held under the finger');

      await finger.up();
      await tester.pump(const Duration(seconds: 2));
      expect(shelf.pixels, held, reason: 'resting after the finger lifts');

      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, greaterThan(held));
    });

    testWidgets('off screen everything stops; back on screen it picks up', (
      tester,
    ) async {
      final page = ScrollController();
      addTearDown(page.dispose);
      await pumpShelf(tester, page: page);
      final shelf = shelfOf(tester);
      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, greaterThan(0));

      page.jumpTo(page.position.maxScrollExtent);
      // The block sees it has left, tells the shelf, and the shelf stops.
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump();
      }
      final parked = shelf.pixels;
      await tester.pump(const Duration(seconds: 5));
      expect(shelf.pixels, parked);
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'nothing ticks while the shelf is off screen',
      );

      page.jumpTo(0);
      await tester.pump();
      await tester.pump();
      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, greaterThan(parked));
    });

    testWidgets('a shelf that fits the screen stays put', (tester) async {
      await pumpShelf(tester, count: HomeCategoryGrid.singleRowMax);
      final shelf = shelfOf(tester);
      expect(shelf.maxScrollExtent, 0);

      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      expect(shelf.pixels, 0);
    });
  });

  group('a still shelf', () {
    for (final (name, reducedMotion, screenReader) in [
      ('reduced motion', true, false),
      ('a screen reader', false, true),
    ]) {
      testWidgets(
        'with $name: shown at once, never moves, asks for no frames',
        (tester) async {
          await pumpShelf(
            tester,
            reducedMotion: reducedMotion,
            screenReader: screenReader,
          );
          expect(entranceOf(tester, 0), 1, reason: 'no cascade');

          await tester.pump(const Duration(seconds: 10));
          expect(shelfOf(tester).pixels, 0);
          expect(tester.binding.hasScheduledFrame, isFalse);
        },
      );
    }
  });

  testWidgets('the tiles cascade in from the start edge', (tester) async {
    // Two rows: index 0 is in the first column, index 10 in the sixth.
    await pumpShelf(tester, count: 13);
    expect(entranceOf(tester, 0), 0);

    await tester.pump(const Duration(milliseconds: 200));
    expect(entranceOf(tester, 0), greaterThan(entranceOf(tester, 10)));

    await tester.pump(AppMotion.drawOn);
    expect(entranceOf(tester, 0), 1);
    expect(entranceOf(tester, 10), 1);
  });

  testWidgets('a tile is a plate on a moving wash, with no hill', (
    tester,
  ) async {
    await pumpShelf(tester, count: 13);

    expect(find.byType(HomeTileBackdrop), findsNothing);
    final washes = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is HomeCategoryAuroraPainter,
    );
    expect(
      washes,
      findsNWidgets(find.byType(HomeCategoryTile).evaluate().length),
    );

    final wash =
        tester.widget<CustomPaint>(washes.first).painter!
            as HomeCategoryAuroraPainter;
    final before = wash.progress.value;
    // BX-03: still through the rest before the first burst.
    await tester.pump(AppMotion.carousel - const Duration(seconds: 1));
    expect(wash.progress.value, before, reason: 'the wash rests');

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(wash.progress.value, isNot(before), reason: 'the wash drifts');

    // The burst ends within one ambient budget, and the wash rests again.
    await tester.pump(AppMotion.ambientBudget);
    await tester.pump(_frame);
    final rested = wash.progress.value;
    await tester.pump(AppMotion.carousel ~/ 2);
    expect(wash.progress.value, rested);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('a tile never shares its colour with the next one in either row', () {
    for (var i = 0; i < 40; i++) {
      expect(
        HomeCategoryTile.accentAt(i),
        isNot(HomeCategoryTile.accentAt(i + 1)),
      );
      expect(
        HomeCategoryTile.accentAt(i),
        isNot(HomeCategoryTile.accentAt(i + 2)),
      );
    }
  });
}
