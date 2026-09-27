import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/design/jameia_cart_mark.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_assembly.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_basket_choreography.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_beat.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_burst_choreography.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_layout.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_variant.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_wordmark_choreography.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_wordmark_geometry.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_wordmark_glyphs.dart';

const Size _phone = Size(390, 844);
const double _tolerance = 1e-9;

void main() {
  final layout = SplashLayout(_phone);

  group('every variant', () {
    for (final variant in SplashVariant.values) {
      final choreography = variant.choreography;
      final total = choreography.duration.inMilliseconds.toDouble();

      test('${variant.name} starts on the launch-screen frame', () {
        final frame = choreography.frameAt(0, layout);

        expect(frame.cartCenter, layout.center);
        expect(frame.cartUnit, closeTo(SplashLayout.nativeUnit, _tolerance));
        expect(frame.squash, 0);
        expect(frame.lift, 0);
        expect(frame.speedLines, 0);
        expect(frame.burst, 0);
        expect(frame.swoosh, 0);
        expect(frame.leaf, 0);
        expect(frame.letters, everyElement(0));
        expect(frame.groceries, everyElement(0));
        // Flat like the native splash: no glow, rings, confetti or shine.
        expect(frame.ambient, 0);
        expect(frame.ripples, isEmpty);
        expect(frame.confetti, 0);
        expect(frame.shine, 0);
      });

      test('${variant.name} ends on the finished lockup', () {
        final frame = choreography.frameAt(total, layout);

        expect(frame.cartCenter.dx, closeTo(layout.lockupCartCenter.dx, 1e-6));
        expect(frame.cartCenter.dy, closeTo(layout.lockupCartCenter.dy, 1e-6));
        expect(frame.cartUnit, closeTo(layout.lockupCartUnit, _tolerance));
        expect(frame.squash, closeTo(0, _tolerance));
        expect(frame.speedLines, 0);
        expect(frame.letters, hasLength(SplashWordmarkGlyphs.letters.length));
        expect(frame.letters, everyElement(closeTo(1, _tolerance)));
        expect(frame.swoosh, closeTo(1, _tolerance));
        expect(frame.stripes, closeTo(1, _tolerance));
        expect(frame.leaf, closeTo(1, _tolerance));
        expect(frame.groceries, everyElement(closeTo(1, _tolerance)));
      });

      test('${variant.name} brings the colour glow in as it starts', () {
        expect(
          choreography.frameAt(SplashAssembly.ambientLength, layout).ambient,
          closeTo(1, _tolerance),
        );
        expect(choreography.frameAt(total, layout).shine, closeTo(1, 1e-6));
      });

      test('${variant.name} fades the tagline in before the hand-off', () {
        expect(choreography.tagline.begin, greaterThan(0));
        expect(choreography.tagline.end, lessThanOrEqualTo(1));
      });
    }
  });

  test('every assembly settles before its hand-off', () {
    final runs = <(double, double)>[
      (
        SplashWordmarkChoreography.assembly.end,
        AppMotion.splashWordmark.inMilliseconds.toDouble(),
      ),
      (
        SplashBasketChoreography.assembly.end,
        AppMotion.splashBasket.inMilliseconds.toDouble(),
      ),
      (
        SplashBurstChoreography.assembly.end,
        AppMotion.splashBurst.inMilliseconds.toDouble(),
      ),
    ];
    for (final (end, total) in runs) {
      expect(end, lessThanOrEqualTo(total));
    }
  });

  test('landings send a ring and the cart lands with confetti', () {
    const wordmark = SplashWordmarkChoreography();
    final hopRing = wordmark.frameAt(
      SplashWordmarkChoreography.hopStart +
          SplashWordmarkChoreography.hopLength +
          SplashAssembly.rippleLength / 2,
      layout,
    );
    expect(hopRing.ripples, hasLength(1));
    expect(hopRing.ripples.single.center, layout.nativeCartGround);

    final landed =
        SplashWordmarkChoreography.assembly.start +
        SplashAssembly.landingStart +
        SplashAssembly.rippleLength / 2;
    final frame = wordmark.frameAt(landed, layout);
    expect(
      frame.ripples.map((ring) => ring.center),
      contains(layout.lockupCartGround),
    );
    expect(frame.confetti, inExclusiveRange(0, 1));
    expect(frame.confettiOrigin, layout.lockupCartCenter);
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
    final firstLanding =
        SplashBasketChoreography.firstDrop +
        SplashBasketChoreography.fallLength;
    final frame = basket.frameAt(firstLanding, layout);

    expect(frame.groceries, hasLength(SplashBasketChoreography.groceryCount));
    expect(frame.groceries.first, closeTo(1, _tolerance));
    expect(frame.groceries.last, 0);
  });

  test('the wordmark cart hops before gliding into the "J"', () {
    const wordmark = SplashWordmarkChoreography();
    final midHop =
        SplashWordmarkChoreography.hopStart +
        SplashWordmarkChoreography.hopLength / 2;

    expect(
      wordmark.frameAt(midHop, layout).lift,
      closeTo(SplashWordmarkChoreography.hopHeight, _tolerance),
    );
    expect(wordmark.frameAt(midHop, layout).cartCenter, layout.center);
  });

  group('SplashVariant', () {
    test('defaults to the wordmark intro', () {
      expect(SplashVariant.byName(''), SplashVariant.wordmark);
      expect(SplashVariant.byName('nope'), SplashVariant.wordmark);
      expect(SplashVariant.configured, SplashVariant.wordmark);
    });

    test('picks a variant by name', () {
      expect(SplashVariant.byName('basket'), SplashVariant.basket);
      expect(SplashVariant.byName('burst'), SplashVariant.burst);
    });
  });

  group('geometry', () {
    test('the launch-screen cart fits the circle Android 12+ keeps', () {
      expect(SplashLayout.nativeReach, lessThan(SplashLayout.nativeSafeRadius));
    });

    test('the cart is roughly square, so it reads at icon size', () {
      final bounds = JameiaCartMark.bounds;
      expect(bounds.width / bounds.height, inInclusiveRange(0.9, 1.1));
    });

    for (final width in [320.0, 390.0, 430.0, 800.0]) {
      test('the lockup stays inside a ${width.toInt()} dp wide screen', () {
        final wide = SplashLayout(Size(width, _phone.height));
        final left =
            wide.textOrigin.dx +
            SplashWordmarkGeometry.bounds.left * wide.scale;
        final right =
            wide.textOrigin.dx +
            SplashWordmarkGeometry.bounds.right * wide.scale;

        expect(left, greaterThan(0));
        expect(right, lessThan(width));
        expect(right - left, lessThanOrEqualTo(SplashLayout.lockupMaxWidth));
        expect(wide.taglineTop, greaterThan(wide.center.dy));
      });
    }

    test('the leaf sits on the dotless "ı"', () {
      expect(SplashWordmarkGlyphs.letters, hasLength(9));
      final stem = SplashWordmarkGlyphs.letters[SplashWordmarkGlyphs.leafLetter]
          .getBounds();
      expect(
        SplashWordmarkGeometry.leafBase.dx,
        inInclusiveRange(stem.left, stem.right),
      );
      expect(SplashWordmarkGeometry.leafBase.dy, lessThan(stem.top));
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
