// Motion foundation for the account / auth redesign: the springs settle
// where the M3 tokens say, fade-through ends on the new child only, the money
// ticker is static on first build and rolls on change, the language veil
// commits under itself and always clears, the segmented control reports real
// changes only, and the through transition fades and shifts mid-way.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/fade_through_switcher.dart';
import 'package:hero_mart/src/core/motion/locale_swap_veil.dart';
import 'package:hero_mart/src/core/motion/locale_swap_veil_view.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/rolling_glyph.dart';
import 'package:hero_mart/src/core/motion/rolling_number.dart';
import 'package:hero_mart/src/core/navigation/hero_through_transition.dart';
import 'package:hero_mart/src/core/widgets/hero_segmented_control.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

void main() {
  group('SpringCurve / AppSprings', () {
    test(
      'settle times match the M3 tokens (snappy ≈ 320 ms, calm ≈ 210 ms)',
      () {
        expect(
          AppSprings.snappy.duration.inMilliseconds,
          inInclusiveRange(250, 400),
        );
        expect(
          AppSprings.calm.duration.inMilliseconds,
          inInclusiveRange(150, 280),
        );
      },
    );

    test('starts at 0, ends at 1; snappy overshoots, calm barely', () {
      for (final spring in [AppSprings.snappy, AppSprings.calm]) {
        expect(spring.transform(0), 0);
        expect(spring.transform(1), 1);
      }
      double peak(SpringCurve c) =>
          [for (var i = 1; i < 100; i++) c.transform(i / 100)]
              .reduce((a, b) => a > b ? a : b);
      expect(peak(AppSprings.snappy), greaterThan(1.02));
      expect(peak(AppSprings.calm), lessThan(1.01));
    });
  });

  group('FadeThroughSwitcher', () {
    testWidgets('ends on the new child only', (tester) async {
      await tester.pumpWidget(
        _host(const FadeThroughSwitcher(stateKey: 'a', child: Text('A'))),
      );
      await tester.pumpWidget(
        _host(const FadeThroughSwitcher(stateKey: 'b', child: Text('B'))),
      );
      await tester.pump(AppMotion.page ~/ 2);
      expect(find.text('B'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('RollingNumber', () {
    String format(num v) => v.toStringAsFixed(3);

    testWidgets('static on first build; rolls only the changed glyphs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(RollingNumber(value: 1.250, format: format)),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.bySemanticsLabel('1.250'), findsOneWidget);

      await tester.pumpWidget(
        _host(RollingNumber(value: 1.750, format: format)),
      );
      await tester.pump(AppMotion.medium ~/ 2);
      // Only the "2" → "7" slot is mid-roll: both glyphs are on screen.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);
      expect(find.bySemanticsLabel('1.750'), findsOneWidget);
      expect(find.byType(RollingGlyph), findsNWidgets(5));
    });

    testWidgets('reduced motion swaps at once', (tester) async {
      await tester.pumpWidget(
        _host(RollingNumber(value: 1, format: format), reduced: true),
      );
      await tester.pumpWidget(
        _host(RollingNumber(value: 2, format: format), reduced: true),
      );
      await tester.pump();
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('LocaleSwapVeil', () {
    testWidgets('commits under the veil, then removes it', (tester) async {
      var commits = 0;
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final running = LocaleSwapVeil.run(
        ctx,
        color: Colors.white,
        commit: () async => commits++,
      );
      await tester.pump();
      expect(find.byType(LocaleSwapVeilView), findsOneWidget);
      await tester.pumpAndSettle();
      await running;
      expect(commits, 1);
      expect(find.byType(LocaleSwapVeilView), findsNothing);
    });

    testWidgets('a failing commit still clears the veil and rethrows', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      Object? caught;
      final running = LocaleSwapVeil.run(
        ctx,
        color: Colors.white,
        commit: () async => throw StateError('boom'),
      ).catchError((Object e) => caught = e);
      await tester.pumpAndSettle();
      await running;
      expect(caught, isA<StateError>());
      expect(find.byType(LocaleSwapVeilView), findsNothing);
    });

    testWidgets('reduced motion just commits', (tester) async {
      var commits = 0;
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
          reduced: true,
        ),
      );
      await LocaleSwapVeil.run(
        ctx,
        color: Colors.white,
        commit: () async => commits++,
      );
      await tester.pump();
      expect(commits, 1);
      expect(find.byType(LocaleSwapVeilView), findsNothing);
    });
  });

  group('HeroSegmentedControl', () {
    testWidgets('reports a change once; tapping the selected one is inert', (
      tester,
    ) async {
      final picks = <String>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: HeroSegmentedControl<String>(
              values: const ['en', 'ar'],
              selected: 'en',
              labelOf: (v) => v.toUpperCase(),
              onChanged: picks.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text('EN'));
      await tester.tap(find.text('AR'));
      await tester.pumpAndSettle();
      expect(picks, ['ar']);
      expect(
        tester.getSemantics(find.text('EN')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          hasTapAction: true,
          label: 'EN',
          isFocusable: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });
  });

  group('HeroThroughTransition', () {
    testWidgets('mid-transition the page is partly faded and shifted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const HeroThroughTransition(
            animation: AlwaysStoppedAnimation<double>(0.5),
            shift: AppMotion.slideShift,
            child: Text('page'),
          ),
        ),
      );
      final fades = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.text('page'),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((f) => f.opacity.value);
      expect(fades.any((o) => o > 0 && o < 1), isTrue);
      final shifts = tester
          .widgetList<Transform>(
            find.ancestor(
              of: find.text('page'),
              matching: find.byType(Transform),
            ),
          )
          .map((t) => t.transform.getTranslation().x);
      expect(shifts.any((x) => x > 0), isTrue);
    });

    testWidgets('at rest nothing is shifted or faded', (tester) async {
      await tester.pumpWidget(
        _host(
          const HeroThroughTransition(
            animation: kAlwaysCompleteAnimation,
            shift: AppMotion.slideShift,
            child: Text('page'),
          ),
        ),
      );
      final shifts = tester
          .widgetList<Transform>(
            find.ancestor(
              of: find.text('page'),
              matching: find.byType(Transform),
            ),
          )
          .map((t) => t.transform.getTranslation().x);
      expect(shifts.every((x) => x == 0), isTrue);
    });
  });
}
