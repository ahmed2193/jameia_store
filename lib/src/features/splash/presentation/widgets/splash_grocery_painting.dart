import 'dart:ui';

import '../../../../core/design/hero_mark.dart';
import 'splash_palette.dart';

/// The groceries of the basket scene — a bottle, an orange and a bunch of
/// greens — drawn in the mark's design units at their resting place in the
/// bag, sticking out of its opening. Painted between the cape and the bag,
/// so the bag's front hides their lower half and its handle crosses in
/// front of them.
abstract final class SplashGroceryPainting {
  /// How far above its resting place an item starts falling.
  static const double dropHeight = 80;

  /// Share of the fall over which an item fades in.
  static const double fadeIn = 0.2;

  /// Nothing is drawn below this line (under the bag's front), so no item
  /// shows through the "h" cut out of the bag.
  static final double _hiddenBelow = HeroMark.bagTopLeft.dy + 6;

  static const Rect _bottleBody = Rect.fromLTRB(41, 24, 50, 60);
  static const Rect _bottleNeck = Rect.fromLTRB(43.5, 15, 47.5, 25);
  static const Rect _bottleCap = Rect.fromLTRB(42.5, 11.5, 48.5, 16.5);
  static const double _bottleCorner = 3.5;
  static const double _capCorner = 1.5;

  static const Offset _orange = Offset(57, 36);
  static const double _orangeRadius = 8.5;
  static const Rect _orangeLeaf = Rect.fromLTWH(-2.5, -5, 5, 10);
  static const Offset _orangeLeafAt = Offset(60, 26.5);
  static const double _orangeLeafTurn = 0.6;

  static const Rect _greensLeaf = Rect.fromLTWH(-4.5, -12, 9, 24);
  static const List<(Offset, double)> _greens = [
    (Offset(67, 31), -0.35),
    (Offset(73, 32), 0.4),
    (Offset(70, 26), 0.05),
  ];

  /// Paints each item whose drop in [drops] has begun (see
  /// `SplashFrame.groceries`).
  static void paint(Canvas canvas, SplashPalette palette, List<double> drops) {
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(-100, -100, 200, _hiddenBelow));
    for (var i = 0; i < drops.length; i++) {
      final drop = drops[i];
      if (drop <= 0) continue;
      final alpha = (drop / fadeIn).clamp(0.0, 1.0);
      canvas
        ..save()
        ..translate(0, -(1 - drop) * dropHeight);
      switch (i) {
        case 0:
          _bottle(canvas, palette, alpha);
        case 1:
          _orangeFruit(canvas, palette, alpha);
        default:
          _greensBunch(canvas, palette, alpha);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  static Paint _fill(Color color, double alpha) =>
      Paint()..color = color.withValues(alpha: color.a * alpha);

  static void _bottle(Canvas canvas, SplashPalette palette, double alpha) {
    final body = _fill(palette.bottle, alpha);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          _bottleBody,
          const Radius.circular(_bottleCorner),
        ),
        body,
      )
      ..drawRect(_bottleNeck, body)
      ..drawRRect(
        RRect.fromRectAndRadius(_bottleCap, const Radius.circular(_capCorner)),
        _fill(palette.bottleCap, alpha),
      );
  }

  static void _orangeFruit(Canvas canvas, SplashPalette palette, double alpha) {
    canvas.drawCircle(_orange, _orangeRadius, _fill(palette.fruit, alpha));
    _leafAt(
      canvas,
      _orangeLeafAt,
      _orangeLeafTurn,
      _orangeLeaf,
      _fill(palette.fruitLeaf, alpha),
    );
  }

  static void _greensBunch(Canvas canvas, SplashPalette palette, double alpha) {
    final paint = _fill(palette.greens, alpha);
    for (final (at, turn) in _greens) {
      _leafAt(canvas, at, turn, _greensLeaf, paint);
    }
  }

  static void _leafAt(
    Canvas canvas,
    Offset at,
    double turn,
    Rect shape,
    Paint paint,
  ) {
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(turn)
      ..drawOval(shape, paint)
      ..restore();
  }
}
