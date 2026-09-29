// BX-04 (docs/motion PB-06 / CC-11): CountdownChip and HomeCountdownText tick
// on the page's one SecondClock — N countdowns share one timer and one tick —
// and let go of it when nobody sees them (a hidden tab, a block off screen).
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/second_clock.dart';
import 'package:hero_mart/src/core/motion/second_clock_scope.dart';
import 'package:hero_mart/src/core/widgets/countdown_chip.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_countdown_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  SecondClock scopeClock(WidgetTester tester) =>
      tester.state<SecondClockScopeState>(find.byType(SecondClockScope)).clock;

  group('CountdownChip', () {
    Widget chips(
      DateTime Function() clock,
      DateTime endsAt, {
      bool on = true,
    }) => MaterialApp(
      home: TickerMode(
        enabled: on,
        child: SecondClockScope(
          clock: clock,
          child: Scaffold(
            body: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  // The scope's clock rules, whatever the chip was given.
                  CountdownChip(endsAt: endsAt),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('three chips share the page clock and tick together', (
      tester,
    ) async {
      var now = DateTime(2026, 9, 28, 10);
      final endsAt = now.add(const Duration(minutes: 5));
      await tester.pumpWidget(chips(() => now, endsAt));

      expect(find.textContaining('00:05:00'), findsNWidgets(3));
      final clock = scopeClock(tester);
      expect(clock.debugIsRunning, isTrue);

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('00:04:59'), findsNWidgets(3));
      expect(clock.debugIsRunning, isTrue);
    });

    testWidgets('a hidden page rests the clock; back on stage it is current', (
      tester,
    ) async {
      var now = DateTime(2026, 9, 28, 10);
      final endsAt = now.add(const Duration(minutes: 5));
      await tester.pumpWidget(chips(() => now, endsAt, on: false));

      expect(scopeClock(tester).debugIsRunning, isFalse);

      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      expect(find.textContaining('00:05:00'), findsNWidgets(3));

      await tester.pumpWidget(chips(() => now, endsAt));
      expect(scopeClock(tester).debugIsRunning, isTrue);
      expect(find.textContaining('00:04:57'), findsNWidgets(3));
    });

    testWidgets('the sale ends: the chips leave and the clock stops', (
      tester,
    ) async {
      var now = DateTime(2026, 9, 28, 10);
      final endsAt = now.add(const Duration(seconds: 1));
      await tester.pumpWidget(chips(() => now, endsAt));

      now = endsAt;
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.timer_outlined), findsNothing);
      expect(scopeClock(tester).debugIsRunning, isFalse);
    });

    testWidgets('without a scope, a hidden chip does not tick', (tester) async {
      var now = DateTime(2026, 9, 28, 10);
      final endsAt = now.add(const Duration(minutes: 5));
      Widget chip({required bool on}) => MaterialApp(
        home: TickerMode(
          enabled: on,
          child: Scaffold(
            body: CountdownChip(endsAt: endsAt, clock: () => now),
          ),
        ),
      );
      await tester.pumpWidget(chip(on: false));

      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('00:05:00'), findsOneWidget);

      await tester.pumpWidget(chip(on: true));
      expect(find.textContaining('00:04:58'), findsOneWidget);
    });
  });

  group('HomeCountdownText', () {
    // The text sits [below] logical pixels down a feed: past the screen
    // it is off screen (its own on-screen gate, no longer the home block's).
    Widget text(ScrollController scroll, {double below = 0}) => MaterialApp(
      home: SecondClockScope(
        child: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                SizedBox(height: below),
                HomeCountdownText(
                  endsAt: DateTime.now().add(const Duration(hours: 1)),
                  style: const TextStyle(),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('ticks on the page clock while it is on screen', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(text(scroll));
      await tester.pump();

      expect(scopeClock(tester).debugIsRunning, isTrue);
    });

    testWidgets('off screen it lets go of the clock: no timer runs', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(text(scroll, below: 3000));
      await tester.pump();

      final clock = scopeClock(tester);
      expect(clock.debugIsRunning, isFalse);

      scroll.jumpTo(3000);
      await tester.pump();
      await tester.pump();
      expect(clock.debugIsRunning, isTrue);
    });
  });
}
