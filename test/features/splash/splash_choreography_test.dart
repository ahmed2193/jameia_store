import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_mark.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_assembly.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_basket_choreography.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_beat.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_burst_choreography.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_choreography.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_layout.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_variant.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_wordmark.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_wordmark_choreography.dart';

const Size _phone = Size(390, 844);
const double _tolerance = 1e-9;

/// The assembly each choreography ends with.
SplashAssembly _assemblyOf(SplashChoreography choreography) =>
    switch (choreography) {
      SplashBasketChoreography() => SplashBasketChoreography.assembly,
      SplashBurstChoreography() => SplashBurstChoreography.assembly,
      _ => SplashWordmarkChoreography.assembly,
    };

void main() {
  for (final wordmark in SplashWordmark.values) {
    final layout = SplashLayout(_phone, wordmark);

    group('every variant (${wordmark.name})', () {
      for (final variant in SplashVariant.values) {
        final choreography = variant.choreography;
        final total = choreography.duration.inMilliseconds.toDouble();

        test('${variant.name} starts on the launch-screen frame', () {
          final frame = choreography.frameAt(0, layout);

          expect(frame.markCenter, layout.nativeMarkCenter);
          expect(frame.markUnit, closeTo(SplashLayout.nativeUnit, _tolerance));
          expect(frame.squash, 0);
          expect(frame.lift, 0);
          expect(frame.lean, 0);
          // The cape rests exactly as on the launch image.
          expect(frame.capeWave, HeroMark.restWave);
          expect(frame.capePhase, HeroMark.restPhase);
          expect(frame.capeFold, 0);
          expect(frame.speedLines, 0);
          expect(frame.burst, 0);
          expect(frame.deliveries, isEmpty);
          expect(frame.groceries, everyElement(0));
          // Flat like the native splash: no glow, rings, confetti or shine.
          expect(frame.ambient, 0);
          expect(frame.glowPulse, 0);
          expect(frame.ripples, isEmpty);
          expect(frame.confetti, 0);
          expect(frame.shine, 0);
        });

        test('${variant.name} ends on the finished lockup', () {
          final frame = choreography.frameAt(total, layout);

          expect(frame.markCenter.dx, closeTo(layout.markCenter.dx, 1e-6));
          expect(frame.markCenter.dy, closeTo(layout.markCenter.dy, 1e-6));
          expect(frame.markUnit, closeTo(layout.markUnit, _tolerance));
          expect(frame.squash, closeTo(0, _tolerance));
          expect(frame.lean, closeTo(0, _tolerance));
          expect(frame.capeWave, closeTo(HeroMark.restWave, _tolerance));
          expect(frame.capeFold, closeTo(0, _tolerance));
          expect(frame.speedLines, 0);
          expect(frame.deliveries, hasLength(wordmark.pieces.length));
          for (final delivery in frame.deliveries) {
            expect(delivery.flight, 1);
            expect(delivery.squash, 0);
          }
          expect(frame.groceries, everyElement(closeTo(1, _tolerance)));
          expect(frame.shine, closeTo(1, 1e-6));
        });

        // B1-14: the burst plays out inside the clock — it never freezes
        // mid-flight under the fade-through.
        test('${variant.name} confetti lands and fades before the clock '
            'completes', () {
          final landed = SplashAssembly.lastLanding(wordmark);
          final start = _assemblyOf(choreography).start;
          final mid = choreography.frameAt(
            start + landed + SplashAssembly.confettiDelay + 1,
            layout,
          );
          expect(mid.confetti, inExclusiveRange(0, 1), reason: 'it plays');
          expect(
            choreography.frameAt(total, layout).confetti,
            greaterThanOrEqualTo(1),
            reason: 'nothing left to paint on the last frame',
          );
          expect(
            _assemblyOf(choreography).confettiRunIn(wordmark, total),
            greaterThan(0),
          );
        });

        test('${variant.name} settles before its hand-off', () {
          expect(_assemblyOf(choreography).end(wordmark), lessThan(total));
        });

        test('${variant.name} fades the tagline in before the hand-off', () {
          final tagline = choreography.tagline(wordmark);
          expect(tagline.begin, greaterThan(0));
          expect(tagline.end, lessThanOrEqualTo(1));
        });

        test('${variant.name} brings the colour glow in as it starts', () {
          expect(
            choreography.frameAt(SplashAssembly.ambientLength, layout).ambient,
            closeTo(1, _tolerance),
          );
        });
      }
    });
  }

  final layout = SplashLayout(_phone, SplashWordmark.latin);
  const hero = SplashWordmarkChoreography();

  test('the bag takes off, swoops up and tips back in flight', () {
    const midFlight = SplashAssembly.takeOff + SplashAssembly.flightLength / 2;
    final frame = hero.frameAt(midFlight, layout);

    expect(frame.markCenter.dy, lessThan(layout.markCenter.dy));
    expect(frame.markCenter.dy, lessThan(layout.nativeMarkCenter.dy));
    expect(frame.lean, lessThan(0));
    expect(frame.capeWave, greaterThan(HeroMark.restWave));
    expect(frame.capeFold, greaterThan(0));
    expect(frame.speedLines, greaterThan(0));
  });

  test('it crouches before it leaves the ground', () {
    final crouched = hero.frameAt(SplashAssembly.crouchLength, layout);
    expect(crouched.squash, greaterThan(0));
    expect(crouched.markCenter, layout.nativeMarkCenter);
  });

  test('take-off and arrival each send a ring', () {
    final takeOff = hero.frameAt(
      SplashAssembly.takeOff + SplashAssembly.rippleLength / 4,
      layout,
    );
    expect(
      takeOff.ripples.where((ring) => ring.ground).map((ring) => ring.center),
      contains(layout.nativeGround),
    );

    final arrived = hero.frameAt(
      SplashAssembly.arrival + SplashAssembly.rippleLength / 2,
      layout,
    );
    final air = arrived.ripples.where((ring) => !ring.ground);
    expect(air.map((ring) => ring.center), contains(layout.markCenter));
    expect(arrived.glowPulse, greaterThan(0));
  });

  test('the bag delivers the name piece by piece, then celebrates', () {
    final wordmark = layout.wordmark;
    final second = SplashAssembly.launchOf(wordmark, 1);
    final early = hero.frameAt(second, layout);
    expect(early.deliveries, hasLength(2));
    expect(early.deliveries.first.flight, inExclusiveRange(0, 1));
    expect(early.deliveries.last.flight, 0);
    expect(early.confetti, 0);

    final landed = SplashAssembly.lastLanding(wordmark);
    final done = hero.frameAt(
      landed + SplashAssembly.confettiDelay + SplashAssembly.confettiLength / 2,
      layout,
    );
    expect(done.deliveries.map((d) => d.flight), everyElement(1));
    expect(done.confetti, inExclusiveRange(0, 1));
    expect(done.confettiOrigin, layout.wordCenter);
  });

  test('a piece squashes as it lands', () {
    final landing =
        SplashAssembly.launchOf(layout.wordmark, 0) +
        SplashAssembly.deliveryLength +
        SplashAssembly.landingLength / 2;
    final frame = hero.frameAt(landing, layout);
    expect(frame.deliveries.first.flight, 1);
    expect(frame.deliveries.first.squash, greaterThan(0));
  });

  test('the arrived bag floats and its cape keeps rippling', () {
    final end = hero.duration.inMilliseconds.toDouble();
    final a = hero.frameAt(end - 400, layout);
    final b = hero.frameAt(end, layout);
    expect(a.lift, isNot(closeTo(b.lift, 1e-3)));
    expect(a.capePhase, isNot(closeTo(b.capePhase, 1e-3)));
  });

  test('only the burst turns the screen white', () {
    const burst = SplashBurstChoreography();
    final total = burst.duration.inMilliseconds.toDouble();

    expect(burst.frameAt(total, layout).burst, closeTo(1, _tolerance));
    expect(burst.isBrandTopAt(0), isTrue);
    expect(burst.isBrandTopAt(total), isFalse);
    for (final other in [
      const SplashWordmarkChoreography(),
      const SplashBasketChoreography(),
    ]) {
      final end = other.duration.inMilliseconds.toDouble();
      expect(other.frameAt(end, layout).burst, 0);
      expect(other.isBrandTopAt(end), isTrue);
    }
  });

  test('the basket drops three groceries, one after another', () {
    const basket = SplashBasketChoreography();
    const firstLanding =
        SplashBasketChoreography.firstDrop +
        SplashBasketChoreography.fallLength;
    final frame = basket.frameAt(firstLanding, layout);

    expect(frame.groceries, hasLength(SplashBasketChoreography.groceryCount));
    expect(frame.groceries.first, closeTo(1, _tolerance));
    expect(frame.groceries[1], lessThan(1));
    expect(frame.groceries.last, lessThan(frame.groceries[1]));
    expect(frame.markCenter, layout.nativeMarkCenter);
  });

  group('SplashVariant', () {
    test('defaults to the hero intro', () {
      expect(SplashVariant.byName(''), SplashVariant.wordmark);
      expect(SplashVariant.byName('nope'), SplashVariant.wordmark);
      expect(SplashVariant.configured, SplashVariant.wordmark);
    });

    test('picks a variant by name', () {
      expect(SplashVariant.byName('basket'), SplashVariant.basket);
      expect(SplashVariant.byName('burst'), SplashVariant.burst);
    });
  });

  group('SplashWordmark', () {
    test('follows the app language', () {
      expect(SplashWordmark.forLanguage('ar'), SplashWordmark.arabic);
      expect(SplashWordmark.forLanguage('en'), SplashWordmark.latin);
    });

    test('"hero" comes letter by letter, "هيرو" run by run', () {
      expect(SplashWordmark.latin.pieces, hasLength(4));
      expect(SplashWordmark.arabic.pieces, hasLength(2));
      for (final wordmark in SplashWordmark.values) {
        final ink = wordmark.ink.inflate(30);
        for (final box in wordmark.pieceBounds) {
          expect(ink.contains(box.topLeft), isTrue);
          expect(ink.contains(box.bottomRight), isTrue);
        }
      }
    });

    test('Arabic reads right to left: the first run is on the right', () {
      final bounds = SplashWordmark.arabic.pieceBounds;
      expect(bounds.first.center.dx, greaterThan(bounds.last.center.dx));
    });
  });

  group('geometry', () {
    test('the launch-screen mark fits the circle Android 12+ keeps', () {
      expect(SplashLayout.nativeReach, lessThan(SplashLayout.nativeSafeRadius));
    });

    for (final wordmark in SplashWordmark.values) {
      for (final width in [320.0, 390.0, 430.0, 800.0]) {
        test(
          'the ${wordmark.name} lockup fits a ${width.toInt()} dp wide screen',
          () {
            final wide = SplashLayout(Size(width, _phone.height), wordmark);
            final lockup = wide.lockupBounds;

            expect(lockup.left, greaterThan(0));
            expect(lockup.right, lessThan(width));
            expect(wide.taglineTop, greaterThan(lockup.bottom));
            expect(wide.taglineTop, greaterThan(wide.center.dy));
          },
        );
      }
    }

    test('the bag, not its cape, stands centred over the name', () {
      final bag = SplashLayout.pointOf(
        HeroMark.bagCenter,
        layout.markCenter,
        layout.markUnit,
      );
      expect(bag.dx, closeTo(layout.center.dx, 1e-6));
      expect(layout.wordCenter.dx, closeTo(layout.center.dx, 1e-6));
      expect(layout.markCenter.dy, lessThan(layout.wordCenter.dy));
    });
  });

  group('SplashBeat', () {
    test('span clamps and eases', () {
      expect(SplashBeat.span(-10, 0, 100), 0);
      expect(SplashBeat.span(50, 0, 100), 0.5);
      expect(SplashBeat.span(200, 0, 100), 1);
      expect(SplashBeat.span(5, 5, 0), 1);
    });

    test('arc is exactly zero outside its beat', () {
      expect(SplashBeat.arc(0, 0, 100), 0);
      expect(SplashBeat.arc(100, 0, 100), 0);
      expect(SplashBeat.arc(50, 0, 100), closeTo(1, _tolerance));
    });
  });
}
