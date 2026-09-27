// The ambient / reveal motion primitives added for the Pro paywall and the
// rewards screen: they settle, they stay still under reduced motion, a
// count-up lands on the final text, a confetti burst plays once per key, a
// scroll reveal waits until its section reaches the visible part of its list,
// and a light sweep draws no frames between sweeps.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/motion_widgets.dart';
import 'package:hero_mart/src/core/navigation/hero_transition_page.dart';
import 'package:hero_mart/src/core/widgets/light_sweep.dart';
import 'package:hero_mart/src/core/widgets/light_sweep_band.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Scaffold(body: child),
    ),
  ),
);

/// The opacity of [reveal]'s own fade (not the route transition's), also
/// for an item laid out in a list's cache area.
double _opacityOf(WidgetTester tester, Finder reveal) {
  final fade = tester.widget<FadeTransition>(
    find
        .descendant(
          of: reveal,
          matching: find.byType(FadeTransition),
          skipOffstage: false,
        )
        .first,
  );
  return fade.opacity.value;
}

Finder _reveal(String text) => find.ancestor(
  of: find.text(text, skipOffstage: false),
  matching: find.byType(ScrollReveal),
);

void main() {
  group('FloatLoop / GlowPulse', () {
    testWidgets('loop while animations are on', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              FloatLoop(child: Text('bag')),
              GlowPulse(color: Colors.amber, diameter: 40),
            ],
          ),
        ),
      );
      await tester.pump(AppMotion.floatLoop ~/ 4);

      expect(tester.hasRunningAnimations, isTrue);
      // Tearing the tree down disposes both controllers without errors.
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('are still under reduced motion', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              FloatLoop(child: Text('bag')),
              GlowPulse(color: Colors.amber, diameter: 40),
            ],
          ),
          reduced: true,
        ),
      );
      await tester.pump(AppMotion.floatLoop);

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('bag'), findsOneWidget);
    });

    testWidgets('CT-F1 a counted float rests', (tester) async {
      const float = FloatLoop(
        count: 6,
        period: Duration(milliseconds: 100),
        child: Text('hint'),
      );
      await tester.pumpWidget(_host(float));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      // Six legs end where they started (no offset left over).
      final rest = tester.getTopLeft(find.text('hint'));
      expect(
        tester
            .widget<Transform>(
              find
                  .ancestor(
                    of: find.text('hint'),
                    matching: find.byType(Transform),
                  )
                  .first,
            )
            .transform
            .getTranslation()
            .y,
        0,
      );

      // A MediaQuery change reaches didChangeDependencies; the float that
      // already played does not start again.
      await tester.pumpWidget(_host(float, reduced: true));
      await tester.pumpWidget(_host(float));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.getTopLeft(find.text('hint')), rest);
    });
  });

  group('CountUpText', () {
    String format(double v) => v.round().toString();

    testWidgets('counts from [from] and lands on the value', (tester) async {
      await tester.pumpWidget(
        _host(CountUpText(value: 320, from: 0, format: format)),
      );
      await tester.pump(AppMotion.countUp ~/ 2);
      expect(find.text('320'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('320'), findsOneWidget);
      expect(find.bySemanticsLabel('320'), findsOneWidget);
    });

    testWidgets('rolls to a new value', (tester) async {
      await tester.pumpWidget(_host(CountUpText(value: 100, format: format)));
      expect(find.text('100'), findsOneWidget);

      await tester.pumpWidget(_host(CountUpText(value: 200, format: format)));
      await tester.pump(AppMotion.countUp ~/ 2);
      expect(find.text('200'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('reduced motion shows the value at once', (tester) async {
      await tester.pumpWidget(
        _host(CountUpText(value: 320, from: 0, format: format), reduced: true),
      );
      expect(find.text('320'), findsOneWidget);
    });

    int shown(WidgetTester tester) => int.parse(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byType(CountUpText),
              matching: find.byType(Text),
            ),
          )
          .data!,
    );

    testWidgets('a new target mid-count continues from the number on '
        'screen', (tester) async {
      await tester.pumpWidget(
        _host(CountUpText(value: 1000, from: 0, format: format)),
      );
      await tester.pump(const Duration(milliseconds: 35));
      final inFlight = shown(tester);
      expect(inFlight, inInclusiveRange(1, 999));

      await tester.pumpWidget(_host(CountUpText(value: 3000, format: format)));
      expect(shown(tester), inFlight);
      await tester.pump(const Duration(milliseconds: 16));
      // Rising from the in-flight number, not snapping to the old target.
      expect(shown(tester), inInclusiveRange(inFlight, 999));

      await tester.pumpAndSettle();
      expect(shown(tester), 3000);
    });

    testWidgets('a settled value is read once', (tester) async {
      await tester.pumpWidget(_host(CountUpText(value: 320, format: format)));
      expect(tester.getSemantics(find.byType(CountUpText)).label, '320');
    });
  });

  group('LightSweep', () {
    const period = Duration(milliseconds: 1000);
    Widget sweep({bool reduced = false}) => _host(
      const LightSweep(period: period, child: SizedBox(width: 100, height: 40)),
      reduced: reduced,
    );

    testWidgets('sweeps, rests without drawing frames, then sweeps '
        'again', (tester) async {
      await tester.pumpWidget(sweep());
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pump(period * LightSweep.defaultSweepShare);
      await tester.pump();
      // The band is parked off the end edge; nothing ticks until the next
      // period starts.
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pump(period * (1 - LightSweep.defaultSweepShare));
      expect(tester.hasRunningAnimations, isTrue);

      // Tearing the tree down cancels the rest timer and the controller.
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints nothing under reduced motion', (tester) async {
      await tester.pumpWidget(sweep(reduced: true));
      await tester.pump(period);

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(LightSweepBand), findsNothing);
    });
  });

  group('ConfettiBurst', () {
    Widget burst(Object? key, {bool reduced = false}) => _host(
      ConfettiBurst(
        playKey: key,
        colors: const [Colors.purple, Colors.amber],
        child: const Text('page'),
      ),
      reduced: reduced,
    );

    testWidgets('plays once per new key, then goes idle', (tester) async {
      await tester.pumpWidget(burst(null));
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(burst(1));
      await tester.pump(AppMotion.confetti ~/ 2);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      // The same key again does not replay.
      await tester.pumpWidget(burst(1));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('never plays under reduced motion', (tester) async {
      await tester.pumpWidget(burst(null, reduced: true));
      await tester.pumpWidget(burst(1, reduced: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('ScrollReveal', () {
    testWidgets('on screen plays at once; below the fold waits for the '
        'scroll', (tester) async {
      await tester.pumpWidget(
        _host(
          ListView(
            children: const [
              ScrollReveal(child: Text('top')),
              SizedBox(height: 2000),
              ScrollReveal(child: Text('bottom')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('top')), 1);

      await tester.drag(find.byType(ListView), const Offset(0, -1900));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('bottom')), 1);
    });

    testWidgets('a section never scrolled to stays hidden', (tester) async {
      await tester.pumpWidget(
        _host(
          // A Column keeps the far child built so its state can be read.
          const SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 2000),
                ScrollReveal(child: Text('far')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('far')), 0);
    });

    testWidgets('the cascade delay holds only what the first layout shows; '
        'a reveal the scroll brings in plays at once', (tester) async {
      const delay = Duration(milliseconds: 300);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            controller: controller,
            child: const Column(
              children: [
                ScrollReveal(delay: delay, child: Text('top')),
                SizedBox(height: 2000),
                ScrollReveal(delay: delay, child: Text('bottom')),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(_opacityOf(tester, _reveal('top')), 0);

      controller.jumpTo(1900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      // 100 ms after the scroll, well inside the 300 ms delay.
      expect(_opacityOf(tester, _reveal('bottom')), greaterThan(0));

      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('top')), 1);
      expect(_opacityOf(tester, _reveal('bottom')), 1);
    });

    testWidgets('a bar laid over the list (extendBody) hides what is '
        'under it', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            extendBody: true,
            bottomNavigationBar: const SizedBox(height: 200),
            body: ListView(
              controller: controller,
              children: const [
                SizedBox(height: 420),
                ScrollReveal(child: SizedBox(height: 50, child: Text('under'))),
                SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Top at 420 of a 600-high screen: above 92% of the screen, but under
      // the 200-high bar.
      expect(_opacityOf(tester, _reveal('under')), 0);

      controller.jumpTo(100);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('under')), 1);
    });

    testWidgets('the items of a page sliding in reveal once it is laid '
        'out', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/list',
            pageBuilder: (_, state) => HeroTransitionPage<void>(
              key: state.pageKey,
              // A short list: it never scrolls, so no scroll event follows.
              child: Scaffold(
                body: ListView(
                  children: const [
                    ScrollReveal(child: Text('first')),
                    ScrollReveal(child: Text('second')),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      unawaited(router.push<void>('/list'));
      await tester.pump();
      await tester.pump(AppMotion.page);
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('first')), 1);
      expect(_opacityOf(tester, _reveal('second')), 1);
    });

    testWidgets('a one-step jump reveals the item it brings in', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          ListView(
            controller: controller,
            // Keeps the far item laid out before the jump, so its check has
            // to read the geometry after the jump's layout.
            scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
            children: const [
              SizedBox(height: 2000),
              ScrollReveal(child: Text('far')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('far')), 0);

      controller.jumpTo(1900);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, _reveal('far')), 1);
    });

    testWidgets('reduced motion shows the child as is', (tester) async {
      await tester.pumpWidget(
        _host(const ScrollReveal(child: Text('x')), reduced: true),
      );
      expect(
        find.descendant(
          of: find.byType(ScrollReveal),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });
  });
}
