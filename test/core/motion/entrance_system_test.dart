// I6 (docs/motion B1-07, B1-08, B1-06, BX-07): the one list entrance
// (EntranceCascade / EntranceCascadeItem) plays on the FIRST arrival only —
// never on scroll-back, a filter or under the page's own transition — is
// capped at staggerMaxItems, fades without rising under reduced motion; the
// skeleton → content cross-fade; the one show / hide (SizeFadeTransition via
// CollapseReveal) and the inline field error built on it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/collapse_reveal.dart';
import 'package:hero_mart/src/core/motion/entrance_arrival.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade_item.dart';
import 'package:hero_mart/src/core/motion/fade_through_switcher.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/size_fade_transition.dart';
import 'package:hero_mart/src/core/widgets/inline_field_error.dart';

Widget _app(Widget child, {bool off = false, bool screenReader = false}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: off,
            accessibleNavigation: screenReader,
          ),
          child: Scaffold(body: child),
        ),
      ),
    );

/// iOS "Reduce Motion" without "Remove animations": reduced && !off.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(reduceMotion: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The item's fade, or null when it simply shows.
FadeTransition? _fadeOf(WidgetTester tester, Finder item) {
  final fades = find.descendant(
    of: item,
    matching: find.byType(FadeTransition),
  );
  if (fades.evaluate().isEmpty) return null;
  return tester.widget<FadeTransition>(fades.first);
}

/// How far the item is lifted below its place, 0 when it does not rise.
double _riseOf(WidgetTester tester, Finder item) {
  final moves = find.descendant(of: item, matching: find.byType(Transform));
  if (moves.evaluate().isEmpty) return 0;
  return tester.widget<Transform>(moves.first).transform.getTranslation().y;
}

Widget _list(ScrollController controller, {int count = 30}) => EntranceCascade(
  child: ListView.builder(
    controller: controller,
    itemCount: count,
    itemBuilder: (context, index) => EntranceCascadeItem(
      key: ValueKey<int>(index),
      index: index,
      child: SizedBox(height: 100, child: Text('row $index')),
    ),
  ),
);

void main() {
  group('EntranceCascade — first load only (B1-08)', () {
    testWidgets('plays once, then never on scroll-back', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(_app(_list(scroll)));

      final first = find.byKey(const ValueKey<int>(0));
      expect(_fadeOf(tester, first)!.opacity.value, 0);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(_fadeOf(tester, first)!.opacity.value, 1);

      // Far enough that the lazy list drops the first rows, then back.
      scroll.jumpTo(2500);
      await tester.pump();
      expect(find.text('row 0'), findsNothing);
      expect(
        _fadeOf(tester, find.byKey(const ValueKey<int>(26))),
        isNull,
        reason: 'reached later: as is',
      );

      scroll.jumpTo(0);
      await tester.pump();
      expect(find.text('row 0'), findsOneWidget);
      expect(_fadeOf(tester, first), isNull, reason: 'rebuilt as is');
    });

    testWidgets('is capped at staggerMaxItems, 30 ms apart', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      // 100-high rows: the 600-high screen + cache builds more than 6.
      await tester.pumpWidget(_app(_list(scroll)));

      for (var i = 0; i < AppMotion.staggerMaxItems; i++) {
        expect(
          _fadeOf(tester, find.byKey(ValueKey<int>(i))),
          isNotNull,
          reason: 'row $i cascades',
        );
      }
      expect(
        _fadeOf(
          tester,
          find.byKey(const ValueKey<int>(AppMotion.staggerMaxItems)),
        ),
        isNull,
      );

      await tester.pump();
      await tester.pump(AppMotion.staggerStep * 2);
      final zero = _fadeOf(tester, find.byKey(const ValueKey<int>(0)))!;
      final five = _fadeOf(tester, find.byKey(const ValueKey<int>(5)))!;
      expect(zero.opacity.value, greaterThan(five.opacity.value));
      expect(_riseOf(tester, find.byKey(const ValueKey<int>(0))), lessThan(8));
      await tester.pumpAndSettle();
    });

    testWidgets('rises entranceRise (8 dp) and lands in place', (tester) async {
      await tester.pumpWidget(
        _app(
          const EntranceCascade(
            child: EntranceCascadeItem(index: 0, child: Text('row')),
          ),
        ),
      );
      final item = find.byType(EntranceCascadeItem);
      expect(_riseOf(tester, item), AppMotion.entranceRise);
      await tester.pumpAndSettle();
      expect(_riseOf(tester, item), 0);
    });

    testWidgets('a scope that stays mounted plays on the first arrival only', (
      tester,
    ) async {
      Widget listing({required bool ready}) => _app(
        EntranceCascade(
          ready: ready,
          child: ready
              ? const EntranceCascadeItem(index: 0, child: Text('card'))
              : const Text('bones'),
        ),
      );
      await tester.pumpWidget(listing(ready: false));
      await tester.pumpWidget(listing(ready: true));
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNotNull);
      await tester.pumpAndSettle();

      // A new sort / filter: loading again, then the new list.
      await tester.pumpWidget(listing(ready: false));
      await tester.pumpWidget(listing(ready: true));
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('never under its own route transition', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const SizedBox()),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: EntranceCascade(
              child: EntranceCascadeItem(index: 0, child: Text('pushed')),
            ),
          ),
        ),
      );
      // Mid-transition (the first frame is laid out offstage for heroes).
      await tester.pump();
      await tester.pump(AppMotion.fast);
      expect(find.text('pushed'), findsOneWidget);
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('play: false and a screen reader mount the items at rest', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const EntranceCascade(
            play: false,
            child: EntranceCascadeItem(index: 0, child: Text('history')),
          ),
        ),
      );
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _app(
          const EntranceCascade(
            child: EntranceCascadeItem(index: 0, child: Text('read out')),
          ),
          screenReader: true,
        ),
      );
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNull);
    });
  });

  group('reduced motion', () {
    testWidgets('reduced (not off): one fast fade, no rise, no stagger', (
      tester,
    ) async {
      _reduceMotion(tester);
      await tester.pumpWidget(
        _app(
          const EntranceCascade(
            child: Column(
              children: [
                EntranceCascadeItem(index: 0, child: Text('a')),
                EntranceCascadeItem(index: 4, child: Text('b')),
              ],
            ),
          ),
        ),
      );
      final items = find.byType(EntranceCascadeItem);
      expect(_riseOf(tester, items.at(0)), 0);
      expect(_riseOf(tester, items.at(1)), 0);

      await tester.pump();
      await tester.pump(AppMotion.fast ~/ 2);
      final a = _fadeOf(tester, items.at(0))!.opacity.value;
      final b = _fadeOf(tester, items.at(1))!.opacity.value;
      expect(a, greaterThan(0));
      expect(b, a, reason: 'the whole list fades together');

      await tester.pump(AppMotion.fast);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('off: the items are simply there', (tester) async {
      await tester.pumpWidget(
        _app(
          const EntranceCascade(
            child: EntranceCascadeItem(index: 0, child: Text('row')),
          ),
          off: true,
        ),
      );
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('EntranceCascadeItem.single', () {
    testWidgets('plays on mount without a scope; play: false rests', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const EntranceCascadeItem.single(child: Text('sent'))),
      );
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNotNull);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _app(
          const EntranceCascadeItem.single(
            key: ValueKey<String>('history'),
            play: false,
            child: Text('from history'),
          ),
        ),
      );
      expect(_fadeOf(tester, find.byType(EntranceCascadeItem)), isNull);
    });

    testWidgets('hands its arrival down to the touches inside', (tester) async {
      final seen = <Animation<double>>[];
      await tester.pumpWidget(
        _app(
          EntranceCascadeItem.single(
            child: Builder(
              builder: (context) {
                seen.add(EntranceArrival.of(context));
                return const SizedBox(height: 10);
              },
            ),
          ),
        ),
      );
      expect(seen.last.value, 0);
      await tester.pumpAndSettle();
      expect(seen.last.value, 1);
    });
  });

  group('FadeThroughSwitcher.crossFade (skeleton → content)', () {
    Widget swap(String state) => _app(
      FadeThroughSwitcher(stateKey: state, crossFade: true, child: Text(state)),
    );

    testWidgets('cross-fades both over fast, no scale, no gap', (tester) async {
      await tester.pumpWidget(swap('bones'));
      await tester.pumpWidget(swap('list'));
      await tester.pump(AppMotion.fast ~/ 2);
      expect(find.text('bones'), findsOneWidget);
      expect(find.text('list'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('list'),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
      final incoming = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('list'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(incoming.opacity.value, greaterThan(0), reason: 'no blank gap');

      await tester.pump(AppMotion.fast);
      expect(find.text('bones'), findsNothing);
    });

    testWidgets('reduced: the swap is instant', (tester) async {
      _reduceMotion(tester);
      await tester.pumpWidget(swap('bones'));
      await tester.pumpWidget(swap('list'));
      await tester.pump();
      expect(find.text('bones'), findsNothing);
      expect(find.text('list'), findsOneWidget);
    });
  });

  group('SizeFadeTransition / CollapseReveal (BX-07)', () {
    testWidgets('opens its height, then fades the content in', (tester) async {
      Widget block(bool visible) => _app(
        Column(
          children: [
            CollapseReveal(
              visible: visible,
              child: const SizedBox(height: 100, child: Text('notice')),
            ),
          ],
        ),
      );
      await tester.pumpWidget(block(false));
      await tester.pumpWidget(block(true));
      await tester.pump(AppMotion.medium ~/ 4);
      final early = tester.getSize(find.byType(SizeFadeTransition)).height;
      final fade = tester.widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(SizeFadeTransition),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(early, greaterThan(0));
      expect(early, lessThan(100));
      expect(fade.opacity.value, lessThan(early / 100));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SizeFadeTransition)).height, 100);

      // Closes faster than it opened (fast vs medium).
      await tester.pumpWidget(block(false));
      await tester.pump(AppMotion.fast ~/ 3);
      expect(find.text('notice'), findsOneWidget, reason: 'drawn as it closes');
      await tester.pump(AppMotion.fast);
      await tester.pump(AppMotion.microPop);
      expect(find.text('notice'), findsNothing);
    });

    testWidgets('reduced: shows and hides at once', (tester) async {
      _reduceMotion(tester);
      Widget block(bool visible) =>
          _app(CollapseReveal(visible: visible, child: const Text('notice')));
      await tester.pumpWidget(block(false));
      await tester.pumpWidget(block(true));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('notice'), findsOneWidget);

      await tester.pumpWidget(block(false));
      await tester.pump();
      expect(find.text('notice'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('InlineFieldError opens under its field and folds away', (
      tester,
    ) async {
      Widget field(String? message) => _app(
        Column(
          children: [
            const Text('field'),
            InlineFieldError(message: message),
          ],
        ),
      );
      await tester.pumpWidget(field(null));
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);

      await tester.pumpWidget(field('Enter a valid number'));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid number'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Enter a valid number')).dy,
        greaterThan(tester.getTopLeft(find.text('field')).dy),
      );

      await tester.pumpWidget(field(null));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid number'), findsNothing);
    });
  });
}
