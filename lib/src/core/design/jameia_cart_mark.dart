import 'dart:math' as math;
import 'dart:ui';

/// The JameiaMart cart mark — the "J" of the wordmark drawn as a shopping
/// cart: a handle bar with a ball knob, the stem, a basket bowl with yellow
/// slats and two wheels. Plain shapes in a [designSize]-unit square, y down.
///
/// Every place the brand shows draws from these same shapes: the splash
/// painters, the native launch images and app icons (`tool/splash/`) and the
/// Home tab's `JameiaMarkIcon`. So the first Flutter frame repeats the OS
/// splash exactly, and the Home tab repeats the launcher icon.
abstract final class JameiaCartMark {
  static const double designSize = 100;

  /// Width of the handle, stem, bowl and rim strokes.
  static const double stroke = 10;

  static const Offset handleStart = Offset(44, 12);
  static const Offset handleEnd = Offset(80, 12);
  static const Offset knob = Offset(86, 12);
  static const double knobRadius = 7.5;

  static const double stemX = 58;
  static const double rimY = 50;
  static const double bowlCenterX = 32;
  static const Offset bowlCenter = Offset(bowlCenterX, rimY);
  static const double bowlRadius = stemX - bowlCenterX;

  static const List<Offset> wheels = [Offset(20, 90), Offset(46, 90)];
  static const double wheelRadius = 7;

  static const List<double> slatCenters = [19.5, 32, 44.5];
  static const double slatWidth = 9;
  static const double slatTop = 56.5;
  static const double slatBottom = rimY + bowlRadius;

  /// The strokes of the mark: the handle bar, then the stem running into the
  /// bowl, whose rim closes back at the stem.
  static final Path outline = Path()
    ..moveTo(handleStart.dx, handleStart.dy)
    ..lineTo(handleEnd.dx, handleEnd.dy)
    ..moveTo(stemX, handleStart.dy)
    ..lineTo(stemX, rimY)
    ..arcTo(
      Rect.fromCircle(center: bowlCenter, radius: bowlRadius),
      0,
      math.pi,
      false,
    )
    ..lineTo(stemX, rimY);

  /// The inside of the bowl (under the rim).
  static final Path bowl = Path()
    ..moveTo(stemX, rimY)
    ..arcTo(
      Rect.fromCircle(center: bowlCenter, radius: bowlRadius),
      0,
      math.pi,
      false,
    )
    ..close();

  /// The three slat bars, before the bowl's curve trims their bottoms.
  static final Path _slatBars = () {
    const half = slatWidth / 2;
    final path = Path();
    for (final x in slatCenters) {
      path.addRRect(
        RRect.fromLTRBR(
          x - half,
          slatTop,
          x + half,
          slatBottom,
          const Radius.circular(half),
        ),
      );
    }
    return path;
  }();

  /// The slats as they show inside the bowl.
  static final Path slats = Path.combine(
    PathOperation.intersect,
    _slatBars,
    bowl,
  );

  /// The bowl with the slats cut out: the one-colour mark (themed icons, the
  /// resting Home tab) keeps the basket's detail as holes.
  static final Path bowlCutOut = Path.combine(
    PathOperation.difference,
    bowl,
    _slatBars,
  );

  /// Everything the mark paints, strokes, knob and wheels included.
  static final Rect bounds = Rect.fromLTRB(
    bowlCenter.dx - bowlRadius - stroke / 2,
    knob.dy - knobRadius,
    knob.dx + knobRadius,
    wheels.first.dy + wheelRadius,
  );

  /// Where the wheels rest: the pivot of the squash and of the landing shadow.
  static final Offset groundCenter = Offset(bounds.center.dx, bounds.bottom);

  /// Farthest painted point from [bounds]' centre — what has to fit inside
  /// the circle Android 12+ keeps of a splash icon.
  static double get reach {
    final c = bounds.center;
    final points = <double>[
      (knob - c).distance + knobRadius,
      for (final w in wheels) (w - c).distance + wheelRadius,
      (handleStart - c).distance + stroke / 2,
      (Offset(bowlCenter.dx - bowlRadius, rimY) - c).distance + stroke / 2,
      (Offset(bowlCenter.dx, rimY + bowlRadius) - c).distance + stroke / 2,
    ];
    return points.reduce(math.max);
  }
}
