import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_touch.dart';

const Offset _center = Offset(200, 400);

void main() {
  testWidgets('a tap leaves a round ring that fades away', (tester) async {
    final touch = SplashTouch(const TestVSync());
    addTearDown(touch.dispose);

    touch.down(const Offset(80, 120), _center, onCart: false);
    await tester.pump();
    await tester.pump(AppMotion.splashTapRipple ~/ 2);

    expect(touch.ripples, hasLength(1));
    expect(touch.ripples.single.ground, isFalse);
    expect(touch.ripples.single.progress, inExclusiveRange(0, 1));
    expect(touch.cartLift, 0, reason: 'only a tap on the cart makes it hop');

    await tester.pump(AppMotion.splashTapRipple);
    expect(touch.ripples, isEmpty);
  });

  testWidgets('tapping the cart makes it hop, then land', (tester) async {
    final touch = SplashTouch(const TestVSync());
    addTearDown(touch.dispose);

    touch.down(_center, _center, onCart: true);
    await tester.pump();
    await tester.pump(AppMotion.splashCartHop ~/ 2);
    expect(touch.cartLift, closeTo(SplashTouch.hopHeight, 0.5));

    await tester.pump(AppMotion.splashCartHop);
    expect(touch.cartLift, 0);
    expect(touch.cartSquash, 0);
  });

  testWidgets('the glow leans towards the finger and back when it lifts', (
    tester,
  ) async {
    final touch = SplashTouch(const TestVSync());
    addTearDown(touch.dispose);
    const finger = Offset(300, 400);

    touch.down(finger, _center, onCart: false);
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
