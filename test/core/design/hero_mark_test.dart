// The Hero mark's shapes: the bag with its "h" cut out, the cape tied behind
// it with a gap, and the numbers every screen lays the mark out by.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_glyphs.dart';
import 'package:hero_mart/src/core/design/hero_mark.dart';

void main() {
  test('the emblem "h" is a hole in the bag', () {
    final emblemBox = HeroGlyphs.emblem.getBounds();
    final bagBox = HeroMark.bag.getBounds();
    expect(bagBox.contains(emblemBox.topLeft), isTrue);
    expect(bagBox.contains(emblemBox.bottomRight), isTrue);

    // Middle of the "h" stem: bag, but not the bag with the emblem cut out.
    final stem = Offset(emblemBox.left + 3, emblemBox.center.dy);
    expect(HeroGlyphs.emblem.contains(stem), isTrue);
    expect(HeroMark.bag.contains(stem), isTrue);
    expect(HeroMark.bagWithEmblem.contains(stem), isFalse);

    // Beside the "h": still solid bag.
    final beside = Offset(bagBox.left + 3, bagBox.center.dy);
    expect(HeroMark.bagWithEmblem.contains(beside), isTrue);
  });

  test('the handle arches over the bag and is hollow', () {
    const b = HeroMark.handleBase;
    final top = Offset(b.dx, b.dy - HeroMark.handleRadiusY);
    expect(HeroMark.handle.contains(top), isTrue);
    expect(HeroMark.handle.contains(b.translate(0, -3)), isFalse);
    expect(top.dy, lessThan(HeroMark.bagTopLeft.dy));
  });

  test('the cape flows back from behind the bag, with a gap cut', () {
    final cape = HeroMark.capeAtRest.getBounds();
    expect(cape.left, lessThan(HeroMark.bagTopLeft.dx - 20));
    expect(cape.right, lessThanOrEqualTo(HeroMark.capeTieX + 0.01));

    // Just outside the bag's left edge, inside the cape: cut by the gap.
    const nearBag = Offset(34.5, 47);
    expect(HeroMark.capeAtRest.contains(nearBag), isTrue);
    expect(HeroMark.capeWithGap.contains(nearBag), isFalse);
    expect(HeroMark.outsideGap.contains(nearBag), isFalse);

    // Well out in the cloth: kept.
    const cloth = Offset(20, 48);
    expect(HeroMark.capeWithGap.contains(cloth), isTrue);
  });

  test('the resting cape is the cape shape at its rest wave', () {
    final shape = HeroMark.capeShape();
    expect(shape.outline.getBounds(), HeroMark.capeAtRest.getBounds());
  });

  test('waving moves the tips, never the tie', () {
    Rect tie(Path cape) => Path.combine(
      PathOperation.intersect,
      cape,
      Path()..addRect(
        const Rect.fromLTRB(HeroMark.capeTieX - 1, 0, HeroMark.capeTieX, 100),
      ),
    ).getBounds();

    final rest = HeroMark.capeShape();
    final flapped = HeroMark.capeShape(wave: 8, phase: 2.4);
    expect(tie(flapped.outline).top, closeTo(tie(rest.outline).top, 0.35));
    expect(
      tie(flapped.outline).bottom,
      closeTo(tie(rest.outline).bottom, 0.35),
    );
    expect(
      flapped.outline.getBounds().top,
      isNot(closeTo(rest.outline.getBounds().top, 0.5)),
    );
  });

  test('the underside is the lower part of the cape', () {
    final shape = HeroMark.capeShape();
    final cape = shape.outline.getBounds();
    final under = shape.underside.getBounds();
    expect(under.bottom, closeTo(cape.bottom, 0.5));
    expect(under.top, greaterThan(cape.top));
  });

  test('bounds, reach and anchors fit the tilted mark', () {
    final bounds = HeroMark.bounds;
    expect(bounds.width, greaterThan(bounds.height));
    expect(HeroMark.reach, greaterThan(bounds.shortestSide / 2));
    expect(HeroMark.reach, lessThan(bounds.longestSide));

    // Tipped back, nose up: the opening sits left of the bottom middle.
    expect(HeroMark.ground.dx, greaterThan(HeroMark.opening.dx));
    expect(HeroMark.ground.dy, greaterThan(HeroMark.opening.dy));
    expect(bounds.contains(HeroMark.bagCenter), isTrue);
    expect(HeroMark.tilted(HeroMark.pivot), HeroMark.pivot);
  });
}
