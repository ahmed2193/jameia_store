import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/core/motion/motion.dart';
import 'package:jameia_mart/core/motion/motion_widgets.dart';

/// Verifies the SINGLE reduced-motion gate: with `MediaQueryData.disableAnimations`
/// true (OS "remove animations"), every core motion primitive renders its FINAL
/// state with no movement and `MotionGuard` collapses timing to zero.
void main() {
  /// Wrap [child] in a MediaQuery that forces the OS reduced-motion flag.
  Widget reduced(Widget child) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: child),
        ),
      );

  Widget normal(Widget child) => MediaQuery(
        data: const MediaQueryData(disableAnimations: false),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: child),
        ),
      );

  group('MotionGuard', () {
    testWidgets('collapses duration to zero + curve to linear when reduced',
        (tester) async {
      late Duration d;
      late Curve c;
      late bool isReduced;
      await tester.pumpWidget(reduced(Builder(builder: (context) {
        isReduced = MotionGuard.reduced(context);
        d = MotionGuard.duration(context, AppMotion.page);
        c = MotionGuard.curve(context, AppMotion.signature);
        return const SizedBox();
      })));
      expect(isReduced, isTrue);
      expect(d, Duration.zero);
      expect(c, Curves.linear);
    });

    testWidgets('passes duration/curve through when NOT reduced',
        (tester) async {
      late Duration d;
      late Curve c;
      await tester.pumpWidget(normal(Builder(builder: (context) {
        d = MotionGuard.duration(context, AppMotion.page);
        c = MotionGuard.curve(context, AppMotion.signature);
        return const SizedBox();
      })));
      expect(d, AppMotion.page);
      expect(c, AppMotion.signature);
    });
  });

  group('PopScale', () {
    testWidgets('reduced → no ScaleTransition, child rendered at full size',
        (tester) async {
      await tester.pumpWidget(
        reduced(const PopScale(popKey: 1, child: Text('badge'))),
      );
      // Reduced path returns the child directly — no scaling wrapper, no
      // pending animation.
      expect(find.text('badge'), findsOneWidget);
      expect(find.byType(ScaleTransition), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('normal → wraps child in a ScaleTransition (animates)',
        (tester) async {
      await tester.pumpWidget(
        normal(const PopScale(popKey: 1, child: Text('badge'))),
      );
      expect(find.byType(ScaleTransition), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
    });
  });

  group('StaggerEntrance', () {
    testWidgets('reduced → child visible immediately, no transition/delay',
        (tester) async {
      await tester.pumpWidget(
        reduced(const StaggerEntrance(index: 5, child: Text('row'))),
      );
      // No initial frame delay and no Fade/Slide wrapper under reduced motion.
      expect(find.text('row'), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('FlipValue', () {
    testWidgets('reduced → value swap is instant (zero-duration switcher)',
        (tester) async {
      await tester.pumpWidget(
        reduced(const FlipValue(flipKey: 'A', child: Text('A'))),
      );
      expect(find.text('A'), findsOneWidget);

      // Swap the value: under reduced motion the AnimatedSwitcher duration is
      // zero, so the new value is present without advancing any clock.
      await tester.pumpWidget(
        reduced(const FlipValue(flipKey: 'B', child: Text('B'))),
      );
      await tester.pump(); // single frame, no duration needed
      expect(find.text('B'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('PressScale', () {
    testWidgets('reduced → press does not scale (stays at 1.0)',
        (tester) async {
      await tester.pumpWidget(
        reduced(PressScale(onTap: () {}, child: const Text('btn'))),
      );
      // Press down and hold.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('btn')),
      );
      await tester.pump();
      // Find the AnimatedScale created by PressScale; under reduced motion its
      // target scale must remain 1.0 (no shrink), and nothing animates.
      final animScale =
          tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(animScale.scale, 1.0);
      expect(tester.hasRunningAnimations, isFalse);
      await gesture.up();
    });

    testWidgets('normal → press scales below 1.0', (tester) async {
      await tester.pumpWidget(
        normal(PressScale(onTap: () {}, child: const Text('btn'))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('btn')),
      );
      await tester.pump();
      final animScale =
          tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(animScale.scale, lessThan(1.0));
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
