// The 2026 motion foundation (docs/motion §9.2, §9.5): the token scale, the
// MotionGuard semantics (reduced = remove animations OR iOS reduce motion,
// off = remove animations only, ambient loops, the scroll helpers that never
// animate a zero duration), FloatLoop's cycle, PressScale's quiet default and
// the Haptics intent helpers + mute.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/float_loop.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/press_scale.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  ),
);

/// Captures [BuildContext] of a plain child.
class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

/// Records every `HapticFeedback.vibrate` the platform receives.
List<String?> _recordHaptics(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  group('AppMotion tokens', () {
    test('the duration scale', () {
      expect(AppMotion.microPop, const Duration(milliseconds: 100));
      expect(AppMotion.fast, const Duration(milliseconds: 150));
      expect(AppMotion.medium, const Duration(milliseconds: 250));
      expect(AppMotion.page, const Duration(milliseconds: 300));
      expect(AppMotion.slow, const Duration(milliseconds: 400));
    });

    test('the new tokens', () {
      expect(AppMotion.successHold, const Duration(milliseconds: 400));
      expect(AppMotion.blinkPeriod, const Duration(milliseconds: 1000));
      expect(AppMotion.snackDwell, const Duration(milliseconds: 4000));
      expect(AppMotion.ambientBudget, const Duration(milliseconds: 5000));
      expect(AppMotion.pressedScale, 0.97);
      expect(AppMotion.pressedScaleSmall, 0.92);
      expect(AppMotion.slideShift, 30);
      expect(AppMotion.entranceRise, 8);
      expect(AppMotion.staggerMaxItems, 6);
      expect(AppMotion.linear, Curves.linear);
    });

    test('the springs match §5 (ζ .6 k 800 · ζ .9 k 700)', () {
      double ratio(SpringCurve curve) {
        final s = curve.spring;
        return s.damping / (2 * math.sqrt(s.stiffness * s.mass));
      }

      expect(AppSprings.snappy.spring.stiffness, 800);
      expect(ratio(AppSprings.snappy), closeTo(0.6, 0.001));
      expect(AppSprings.calm.spring.stiffness, 700);
      expect(ratio(AppSprings.calm), closeTo(0.9, 0.001));
    });
  });

  group('MotionGuard', () {
    testWidgets('remove animations: reduced AND off', (tester) async {
      late bool reduced;
      late bool off;
      await tester.pumpWidget(
        _host(
          _Probe((context) {
            reduced = MotionGuard.reduced(context);
            off = MotionGuard.off(context);
          }),
          disableAnimations: true,
        ),
      );
      expect(reduced, isTrue);
      expect(off, isTrue);
    });

    testWidgets('iOS reduce motion: reduced, not off', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      late bool reduced;
      late bool off;
      late Duration duration;
      await tester.pumpWidget(
        _host(
          _Probe((context) {
            reduced = MotionGuard.reduced(context);
            off = MotionGuard.off(context);
            duration = MotionGuard.duration(context, AppMotion.page);
          }),
        ),
      );
      expect(reduced, isTrue);
      expect(off, isFalse);
      expect(duration, Duration.zero);
    });

    testWidgets('ambient loops: allowed only when nothing asks otherwise', (
      tester,
    ) async {
      late bool allowed;
      Widget probe() => _Probe((context) {
        allowed = MotionGuard.ambientAllowed(context);
      });

      await tester.pumpWidget(_host(probe()));
      expect(allowed, isTrue);

      await tester.pumpWidget(_host(probe(), disableAnimations: true));
      expect(allowed, isFalse, reason: 'reduced motion');

      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
              child: probe(),
            ),
          ),
        ),
      );
      expect(allowed, isFalse, reason: 'a screen reader');

      await tester.pumpWidget(
        _host(TickerMode(enabled: false, child: probe())),
      );
      expect(allowed, isFalse, reason: 'tickers muted (a hidden tab)');
    });

    Widget list(ScrollController controller, {bool reduced = false}) => _host(
      ListView.builder(
        controller: controller,
        itemCount: 100,
        itemBuilder: (_, i) => SizedBox(height: 50, child: Text('row $i')),
      ),
      disableAnimations: reduced,
    );

    testWidgets('BX-01 scrollTo under reduced motion jumps, never throws', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(list(controller, reduced: true));
      final context = tester.element(find.text('row 0'));
      final position = controller.position;

      await MotionGuard.scrollTo(context, position, position.maxScrollExtent);

      expect(tester.takeException(), isNull);
      expect(position.pixels, position.maxScrollExtent);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('scrollTo glides over the given duration otherwise', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(list(controller));
      final context = tester.element(find.text('row 0'));

      final done = MotionGuard.scrollTo(context, controller.position, 500);
      await tester.pump();
      await tester.pump(AppMotion.page ~/ 2);
      expect(controller.offset, inExclusiveRange(0, 500));
      await tester.pumpAndSettle();
      await done;
      expect(controller.offset, 500);
    });

    testWidgets('pageTo under reduced motion jumps to the page', (
      tester,
    ) async {
      final pages = PageController();
      addTearDown(pages.dispose);
      await tester.pumpWidget(
        _host(
          PageView(
            controller: pages,
            children: const [Text('one'), Text('two'), Text('three')],
          ),
          disableAnimations: true,
        ),
      );

      await MotionGuard.pageTo(tester.element(find.text('one')), pages, 2);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(pages.page, 2);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('FloatLoop', () {
    double lift(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .ancestor(of: find.text('bag'), matching: find.byType(Transform))
              .first,
        )
        .transform
        .getTranslation()
        .y;

    testWidgets('B1-03 one up-and-back cycle takes one period', (tester) async {
      const period = Duration(milliseconds: 1000);
      await tester.pumpWidget(
        _host(
          const FloatLoop(period: period, amplitude: 10, child: Text('bag')),
        ),
      );
      // Half a cycle: at the top.
      await tester.pump(period ~/ 2);
      expect(lift(tester), closeTo(-10, 0.01));
      // The full cycle: back where it started.
      await tester.pump(period ~/ 2);
      expect(lift(tester), closeTo(0, 0.01));
    });
  });

  group('PressScale', () {
    testWidgets('presses to the token depth and fires no haptic by default', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: PressScale(
              onTap: () => taps++,
              child: const SizedBox.square(dimension: 80),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressScale)),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        AppMotion.pressedScale,
      );
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        AppMotion.microPop,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(haptics, isEmpty);
    });
  });

  group('Haptics', () {
    tearDown(() => Haptics.enabled = true);

    testWidgets('intent helpers map onto the §9.5 kinds', (tester) async {
      final calls = _recordHaptics(tester);

      Haptics.cartAdd();
      Haptics.cartAdd(first: true);
      Haptics.cartRemove();
      Haptics.commit();
      Haptics.pick();
      Haptics.destructive();
      Haptics.done();

      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    testWidgets('a burst of refusals buzzes once', (tester) async {
      final calls = _recordHaptics(tester);

      Haptics.refuse();
      Haptics.refuse();
      Haptics.refuse();

      expect(calls, ['HapticFeedbackType.heavyImpact']);
    });

    testWidgets('muted: nothing reaches the platform', (tester) async {
      final calls = _recordHaptics(tester);
      Haptics.enabled = false;

      Haptics.cartAdd();
      Haptics.commit();
      Haptics.done();

      expect(calls, isEmpty);
    });
  });
}
