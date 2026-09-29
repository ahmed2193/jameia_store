// B1-20: horizontal motion mirrors in RTL. The hero's flight swoops forward
// in the name's reading direction — right under "hero", left under "هيرو" —
// tipping back the matching way, with its speed lines trailing behind.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_assembly.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_frame.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_layout.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_wordmark.dart';

SplashFrame _midFlight(SplashWordmark wordmark) {
  final layout = SplashLayout(const Size(390, 844), wordmark);
  return const SplashAssembly(0).frameAt(
    SplashAssembly.takeOff + SplashAssembly.flightLength / 2,
    layout,
    fromCenter: layout.nativeMarkCenter,
    fromUnit: SplashLayout.nativeUnit,
  );
}

void main() {
  test('the Latin name: the flight swoops right, tipping back', () {
    final frame = _midFlight(SplashWordmark.latin);
    expect(SplashWordmark.latin.direction, TextDirection.ltr);
    expect(frame.forward, 1);
    expect(frame.lean, lessThan(0));
  });

  test('the Arabic name: the flight is mirrored', () {
    final latin = _midFlight(SplashWordmark.latin);
    final arabic = _midFlight(SplashWordmark.arabic);
    expect(SplashWordmark.arabic.direction, TextDirection.rtl);
    expect(arabic.forward, -1);
    expect(arabic.lean, closeTo(-latin.lean, 1e-9));
  });
}
