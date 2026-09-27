import 'dart:ui';

import '../../../../core/design/jameia_cart_mark.dart';
import 'splash_grocery_painting.dart';
import 'splash_palette.dart';

/// Draws the cart mark ([JameiaCartMark]) on a canvas. Shared by the
/// splash scene and by the tool that renders the native launch image.
abstract final class SplashCartPainting {
  /// Lift (design units) at which the ground shadow is fully dark.
  static const double shadowFullLift = 16;
  static const double shadowOpacity = 0.35;

  /// Shadow ellipse size as a share of the cart's width / its own width.
  static const double shadowWidth = 0.7;
  static const double shadowHeight = 0.12;

  /// How much the shadow shrinks at full lift.
  static const double shadowShrink = 0.3;

  /// Paints the cart with its painted bounds centred on [center] at [unit]
  /// dp per design unit. [squash] flattens it on its wheels, [lift] raises
  /// it above its shadow (design units), [groceries] drop into the bowl.
  static void paint(
    Canvas canvas, {
    required Offset center,
    required double unit,
    required SplashPalette palette,
    double squash = 0,
    double lift = 0,
    List<double> groceries = const <double>[],
  }) {
    final bounds = JameiaCartMark.bounds;
    final ground = JameiaCartMark.groundCenter;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(unit)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    if (lift > 0) _shadow(canvas, palette, lift);
    canvas.translate(0, -lift);
    if (squash != 0) {
      canvas
        ..translate(ground.dx, ground.dy)
        ..scale(1 + squash, 1 - squash)
        ..translate(-ground.dx, -ground.dy);
    }
    if (groceries.isNotEmpty) {
      SplashGroceryPainting.paint(canvas, palette, groceries);
    }
    canvas
      ..drawPath(JameiaCartMark.bowl, Paint()..color = palette.cartFill)
      // The bowl's curve shapes the bottom of each slat.
      ..save()
      ..clipPath(JameiaCartMark.bowl);
    final slat = Paint()..color = palette.slat;
    const half = JameiaCartMark.slatWidth / 2;
    for (final x in JameiaCartMark.slatCenters) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          x - half,
          JameiaCartMark.slatTop,
          x + half,
          JameiaCartMark.slatBottom,
          const Radius.circular(half),
        ),
        slat,
      );
    }
    canvas.restore();
    final ink = Paint()
      ..color = palette.cartInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = JameiaCartMark.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(JameiaCartMark.outline, ink);
    final dot = Paint()..color = palette.cartInk;
    canvas.drawCircle(JameiaCartMark.knob, JameiaCartMark.knobRadius, dot);
    for (final wheel in JameiaCartMark.wheels) {
      canvas.drawCircle(wheel, JameiaCartMark.wheelRadius, dot);
    }
    canvas.restore();
  }

  static void _shadow(Canvas canvas, SplashPalette palette, double lift) {
    final strength = (lift / shadowFullLift).clamp(0.0, 1.0);
    final bounds = JameiaCartMark.bounds;
    final width = bounds.width * shadowWidth * (1 - shadowShrink * strength);
    canvas.drawOval(
      Rect.fromCenter(
        center: JameiaCartMark.groundCenter,
        width: width,
        height: width * shadowHeight,
      ),
      Paint()
        ..color = palette.shadow.withValues(
          alpha: palette.shadow.a * shadowOpacity * strength,
        ),
    );
  }
}
