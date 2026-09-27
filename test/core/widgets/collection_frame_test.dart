// The Hero collection page frame (offers, flash deals, best sellers, a
// brand): the store's name in a top bar that turns from the hero's warm tint
// to white as the hero scrolls away, the hero itself, underline tabs with an
// ink bar under the open one, the "View cart" pill and a flash-sale clock.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/widgets/collection_app_bar_delegate.dart';
import 'package:hero_mart/src/core/widgets/collection_frame.dart';
import 'package:hero_mart/src/core/widgets/collection_tab_strip.dart';
import 'package:hero_mart/src/core/widgets/collection_tabs_delegate.dart';
import 'package:hero_mart/src/core/widgets/countdown_chip.dart';
import 'package:hero_mart/src/core/widgets/round_outlined_button.dart';
import 'package:hero_mart/src/core/widgets/view_cart_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _store = 'Hero';
const String _heading = 'Best sellers near you';

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

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    TextDirection direction = TextDirection.ltr,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: Directionality(textDirection: direction, child: home),
        ),
      ),
    ),
  );

  /// The top bar's background right now.
  Color barColor(WidgetTester tester) {
    final bar = find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is SliverPersistentHeader &&
            widget.delegate is CollectionAppBarDelegate,
      ),
      matching: find.byType(DecoratedBox),
    );
    final box = tester.widget<DecoratedBox>(bar.first);
    return (box.decoration as BoxDecoration).color!;
  }

  Widget frame({
    VoidCallback? onBack,
    VoidCallback? onSearch,
    Widget? tabs,
    Widget? bottomBar,
  }) => CollectionFrame(
    storeName: _store,
    heading: _heading,
    emoji: '🔥',
    subtitle: 'Picked by shoppers around you',
    onBack: onBack,
    onSearch: onSearch ?? () {},
    tabs: tabs,
    bottomBar: bottomBar,
    bodyBuilder: (context, headers) => CustomScrollView(
      slivers: [
        ...headers,
        SliverList.builder(
          itemCount: 40,
          itemBuilder: (context, i) =>
              SizedBox(height: 120, child: Text('Product $i')),
        ),
      ],
    ),
  );

  group('CollectionFrame', () {
    testWidgets('shows the store in the bar and the hero under it', (
      tester,
    ) async {
      await pumpApp(tester, frame(onBack: () {}));
      await tester.pumpAndSettle();

      expect(find.text(_store), findsOneWidget);
      expect(find.textContaining(_heading, findRichText: true), findsOneWidget);
      expect(find.text('Picked by shoppers around you'), findsOneWidget);
      expect(find.byType(RoundOutlinedButton), findsNWidgets(2));
    });

    testWidgets('has no back button when there is nowhere to go back', (
      tester,
    ) async {
      var searched = 0;
      await pumpApp(tester, frame(onSearch: () => searched++));
      await tester.pumpAndSettle();

      expect(find.byType(RoundOutlinedButton), findsOneWidget);
      await tester.tap(find.byType(RoundOutlinedButton));
      expect(searched, 1);
    });

    testWidgets('the bar turns from the hero tint to white as it scrolls', (
      tester,
    ) async {
      await pumpApp(tester, frame(onBack: () {}));
      await tester.pumpAndSettle();
      expect(barColor(tester), AppColors.collectionCream);

      // Part way: somewhere between the two.
      await tester.drag(find.text('Product 0'), const Offset(0, -40));
      await tester.pump();
      final midway = barColor(tester);
      expect(midway, isNot(AppColors.collectionCream));
      expect(midway, isNot(AppColors.white));

      // The hero is gone: white.
      await tester.drag(find.text('Product 1'), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(barColor(tester), AppColors.white);

      // Back to the top: the tint again.
      await tester.fling(find.text('Product 6'), const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();
      expect(barColor(tester), AppColors.collectionCream);
    });

    testWidgets('pins the tabs under the bar once the hero is gone', (
      tester,
    ) async {
      await pumpApp(
        tester,
        frame(
          onBack: () {},
          tabs: SliverPersistentHeader(
            pinned: true,
            delegate: CollectionTabsDelegate(
              labels: const ['All', 'Snacks', 'Ice cream'],
              selected: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Product 1'), const Offset(0, -1500));
      await tester.pumpAndSettle();

      final bar = tester.getBottomLeft(
        find
            .descendant(
              of: find.byWidgetPredicate(
                (widget) =>
                    widget is SliverPersistentHeader &&
                    widget.delegate is CollectionAppBarDelegate,
              ),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(tester.getTopLeft(find.byType(CollectionTabStrip)).dy, bar.dy);
      expect(find.text('Snacks'), findsOneWidget);
    });

    testWidgets('renders right to left and with reduced motion', (
      tester,
    ) async {
      await pumpApp(
        tester,
        frame(onBack: () {}),
        direction: TextDirection.rtl,
        reducedMotion: true,
      );
      await tester.pump();

      // Back sits at the reading start: the right edge in Arabic.
      final buttons = find.byType(RoundOutlinedButton);
      expect(
        tester.getCenter(buttons.first).dx,
        greaterThan(tester.getCenter(buttons.last).dx),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CollectionTabStrip', () {
    Widget strip({
      required int selected,
      required ValueChanged<int> onSelected,
    }) => Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: CollectionTabStrip(
          labels: const ['All', 'Snacks & Chocolate', 'Ice Cream'],
          selected: selected,
          onSelected: onSelected,
        ),
      ),
    );

    /// The ink bar's horizontal span.
    (double, double) inkBar(WidgetTester tester) {
      final bar = find.byType(AnimatedPositionedDirectional);
      final rect = tester.getRect(bar);
      return (rect.left, rect.right);
    }

    testWidgets('a tap picks a tab; the open one does nothing', (tester) async {
      final picked = <int>[];
      await pumpApp(tester, strip(selected: 0, onSelected: picked.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ice Cream'));
      await tester.tap(find.text('All'));
      expect(picked, [2]);
    });

    testWidgets('the ink bar sits under the open tab and glides to the next', (
      tester,
    ) async {
      var selected = 0;
      late StateSetter rebuild;
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return strip(
              selected: selected,
              onSelected: (i) => setState(() => selected = i),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final all = tester.getRect(find.text('All'));
      var (left, right) = inkBar(tester);
      expect(left, lessThanOrEqualTo(all.left));
      expect(right, greaterThanOrEqualTo(all.right));

      rebuild(() => selected = 1);
      await tester.pumpAndSettle();
      final snacks = tester.getRect(find.text('Snacks & Chocolate'));
      (left, right) = inkBar(tester);
      expect(left, lessThanOrEqualTo(snacks.left));
      expect(right, greaterThanOrEqualTo(snacks.right));
    });

    testWidgets('in Arabic the ink bar still sits under the open tab', (
      tester,
    ) async {
      await pumpApp(
        tester,
        strip(selected: 2, onSelected: (_) {}),
        direction: TextDirection.rtl,
      );
      await tester.pumpAndSettle();

      final ice = tester.getRect(find.text('Ice Cream'));
      final (left, right) = inkBar(tester);
      expect(left, lessThanOrEqualTo(ice.left));
      expect(right, greaterThanOrEqualTo(ice.right));
      // The first tab reads from the right.
      expect(
        tester.getCenter(find.text('All')).dx,
        greaterThan(tester.getCenter(find.text('Ice Cream')).dx),
      );
    });
  });

  group('ViewCartPill', () {
    testWidgets('reads as one button with the count and the total', (
      tester,
    ) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: ViewCartPill(count: 3, totalKd: 4.5, onTap: () => taps++),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('View cart'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^View cart, 3, ')), findsOneWidget);
      await tester.tap(find.byType(ViewCartPill));
      expect(taps, 1);
      semantics.dispose();
    });
  });

  group('CountdownChip', () {
    testWidgets('counts down every second and leaves when the sale ends', (
      tester,
    ) async {
      var now = DateTime(2026, 9, 25, 10);
      final ends = now.add(const Duration(hours: 2, minutes: 14, seconds: 2));
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: CountdownChip(endsAt: ends, clock: () => now),
          ),
        ),
      );

      expect(find.textContaining('02:14:02'), findsOneWidget);
      expect(find.textContaining('Ends in'), findsOneWidget);

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('02:14:01'), findsOneWidget);

      now = ends;
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });

    testWidgets('keeps the clock left to right inside Arabic text', (
      tester,
    ) async {
      final now = DateTime(2026, 9, 25, 10);
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: CountdownChip(
              endsAt: now.add(const Duration(minutes: 5)),
              clock: () => now,
            ),
          ),
        ),
        direction: TextDirection.rtl,
      );

      expect(
        find.textContaining('${Unicode.LRI}00:05:00${Unicode.PDI}'),
        findsOneWidget,
      );
    });

    testWidgets('shows nothing for a sale that already ended', (tester) async {
      final now = DateTime(2026, 9, 25, 10);
      await pumpApp(
        tester,
        Scaffold(
          body: CountdownChip(
            endsAt: now.subtract(const Duration(minutes: 1)),
            clock: () => now,
          ),
        ),
      );

      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });
  });
}
