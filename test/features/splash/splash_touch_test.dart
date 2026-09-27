import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_touch.dart';

const Offset _center = Offset(200, 400);

void main() {
  testWidgets('a tap leaves a round ring that fades away', (tester) async {
    final touch = SplashTouch(const TestVSync());
    addTearDown(touch.dispose);

    touch.down(const Offset(80, 120), _center, onMark: false);
    await tester.pump();
    await tester.pump(AppMotion.splashTapRipple ~/ 2);

    expect(touch.ripples, hasLength(1));
    expect(touch.ripples.single.ground, isFalse);
    expect(touch.ripples.single.progress, inExclusiveRange(0, 1));
    expect(touch.markLift, 0, reason: 'only a tap on the bag makes it hop');

    await tester.pump(AppMotion.splashTapRipple);
    expect(touch.ripples, isEmpty);
  });

  testWidgets('tapping the bag makes it hop and flick its cape, then land', (
    tester,
  ) async {
    final touch = SplashTouch(const TestVSync());
    addTearDown(touch.dispose);

    touch.down(_center, _center, onMark: true);
    await tester.pump();
    await tester.pump(AppMotion.splashMarkHop ~/ 2);
    expect(touch.markLift, closeTo(SplashTouch.hopHeight, 0.5));
    expect(touch.capeFlick, closeTo(SplashTouch.hopWave, 0.5));

    await tester.pump(AppMotion.splashMarkHop);
    expect(touch.markLift, 0);
    expect(touch.markSquash, 0);
    expect(touch.capeFlick, 0);
  });

  testWidgets('the glow leans towards the finger and back when it lifts', (
    tester,
  ) async {
    final touch = SplashTouch(const TestVSync());
    addTearDown(touch.dispose);
    const finger = Offset(300, 400);

    touch.down(finger, _center, onMark: false);
    for (var i = 0; i < 30; i++) {
      await tester.pump(AppMotion.fast ~/ 5);
    }
    final lean = (finger - _center) * SplashTouch.glowFollow;
    expect(touch.glowShift.dx, closeTo(lean.dx, 1));

    touch.up();
    for (var i = 0; i < 30; i++) {
      await tester.pump(AppMotion.fast ~/ 5);
    }
    expect(touch.glowShift.distance, lessThan(1));
  });
}
