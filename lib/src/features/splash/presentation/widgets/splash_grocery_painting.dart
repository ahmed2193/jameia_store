import 'dart:ui';

import 'splash_palette.dart';

/// The groceries of the basket scene — a bottle, an orange and a bunch of
/// greens — drawn in cart design units at their resting place in the bowl.
/// Painted before the bowl so its front hides their lower half.
abstract final class SplashGroceryPainting {
  /// How far above its resting place an item starts falling.
  static const double dropHeight = 130;

  /// Share of the fall over which an item fades in.
  static const double fadeIn = 0.2;

  static const Rect _bottleBody = Rect.fromLTRB(16, 26, 28, 56);
  static const Rect _bottleNeck = Rect.fromLTRB(19.5, 19, 24.5, 27);
  static const Rect _bottleCap = Rect.fromLTRB(18.5, 15.5, 25.5, 20.5);
  static const double _bottleCorner = 3.5;
  static const double _capCorner = 1.5;

  static const Offset _orange = Offset(36, 42);
  static const double _orangeRadius = 9.5;
  static const Rect _orangeLeaf = Rect.fromLTWH(-2.5, -5, 5, 10);
  static const Offset _orangeLeafAt = Offset(39, 31.5);
  static const double _orangeLeafTurn = 0.6;

  static const Rect _greensLeaf = Rect.fromLTWH(-4.5, -11, 9, 22);
  static const List<(Offset, double)> _greens = [
    (Offset(44.5, 37), -0.4),
    (Offset(50, 38.5), 0.35),
    (Offset(47, 33), 0),
  ];

  /// Paints each item whose drop in [drops] has begun (see
  /// `SplashFrame.groceries`).
  static void paint(Canvas canvas, SplashPalette palette, List<double> drops) {
    for (var i = 0; i < drops.length; i++) {
      final drop = drops[i];
      if (drop <= 0) continue;
      final alpha = (drop / fadeIn).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(0, -(1 - drop) * dropHeight);
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
        _fill(palette.slat, alpha),
      );
  }

  static void _orangeFruit(Canvas canvas, SplashPalette palette, double alpha) {
    canvas.drawCircle(_orange, _orangeRadius, _fill(palette.fruit, alpha));
    _leafAt(
      canvas,
      _orangeLeafAt,
      _orangeLeafTurn,
      _orangeLeaf,
      _fill(palette.greens, alpha),
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
