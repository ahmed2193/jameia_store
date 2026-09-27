import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../config/theme/app_colors.dart';
import 'hero_mark.dart';

/// The colours of the mark: [bag] (with its handle), [cape] and the cape's
/// darker [capeUnderside], seen when it twists in flight.
@immutable
class HeroMarkColors {
  const HeroMarkColors({
    required this.bag,
    required this.cape,
    required this.capeUnderside,
  });

  /// One colour for everything (themed icons, the resting Home tab).
  factory HeroMarkColors.mono(Color ink) =>
      HeroMarkColors(bag: ink, cape: ink, capeUnderside: ink);

  /// White bag, yellow cape: the mark on the brand green.
  static const HeroMarkColors onBrand = HeroMarkColors(
    bag: AppColors.white,
    cape: AppColors.accent4,
    capeUnderside: AppColors.proAmber,
  );

  /// Green bag, amber cape: the mark on white.
  static const HeroMarkColors onWhite = HeroMarkColors(
    bag: AppColors.primary,
    cape: AppColors.proAmber,
    capeUnderside: AppColors.accent3,
  );

  final Color bag;
  final Color cape;
  final Color capeUnderside;

  static HeroMarkColors lerp(HeroMarkColors a, HeroMarkColors b, double t) =>
      HeroMarkColors(
        bag: Color.lerp(a.bag, b.bag, t)!,
        cape: Color.lerp(a.cape, b.cape, t)!,
        capeUnderside: Color.lerp(a.capeUnderside, b.capeUnderside, t)!,
      );
}

/// How the mark holds itself in one frame. [rest] is the pose of the icons
/// and the launch image.
@immutable
class HeroMarkPose {
  const HeroMarkPose({
    this.squash = 0,
    this.lift = 0,
    this.lean = 0,
    this.wave = HeroMark.restWave,
    this.phase = HeroMark.restPhase,
    this.fold = 0,
  });

  static const HeroMarkPose rest = HeroMarkPose();

  /// Positive flattens the mark on its bottom edge (wider, shorter),
  /// negative stretches it tall.
  final double squash;

  /// Height above its place, in design units.
  final double lift;

  /// Extra tilt on top of [HeroMark.tilt], radians (negative tips it further
  /// back, nose up).
  final double lean;

  /// The cape's wave: amplitude (design units) and phase (radians).
  final double wave;
  final double phase;

  /// How much of the cape's darker underside shows, 0 → 1.
  final double fold;

  bool get _restingCape =>
      wave == HeroMark.restWave && phase == HeroMark.restPhase && fold == 0;
}

/// Draws [HeroMark] on a canvas. Shared by the splash, the Home tab icon and
/// the tools that render the launch image and the app icons, so they all
/// show the same mark.
abstract final class HeroMarkPainting {
  /// Paints the mark with its painted bounds centred on [center] at [unit]
  /// dp per design unit. [inside] paints in the mark's design space between
  /// the cape and the bag (things sticking out of the bag's opening).
  static void paint(
    Canvas canvas, {
    required Offset center,
    required double unit,
    required HeroMarkColors colors,
    HeroMarkPose pose = HeroMarkPose.rest,
    void Function(Canvas canvas)? inside,
  }) {
    canvas
      ..save()
      ..transform(matrixFor(center: center, unit: unit, pose: pose));
    _cape(canvas, colors, pose);
    inside?.call(canvas);
    final bag = Paint()..color = colors.bag;
    canvas
      ..drawPath(HeroMark.bagWithEmblem, bag)
      ..drawPath(HeroMark.handle, bag)
      ..restore();
  }

  /// The transform [paint] draws the mark's design square with: its bounds
  /// centred on [center] at [unit] dp per unit, lifted, squashed on its
  /// bottom edge and tilted as [pose] says. Map [HeroMark] paths through it
  /// to know where the mark is on screen.
  static Float64List matrixFor({
    required Offset center,
    required double unit,
    HeroMarkPose pose = HeroMarkPose.rest,
  }) {
    final bounds = HeroMark.bounds;
    final ground = HeroMark.ground;
    const pivot = HeroMark.pivot;
    final angle = HeroMark.tilt + pose.lean;
    return (_Affine.translation(center) *
            _Affine.scaling(unit, unit) *
            _Affine.translation(-bounds.center - Offset(0, pose.lift)) *
            _Affine.about(
              ground,
              _Affine.scaling(1 + pose.squash, 1 - pose.squash),
            ) *
            _Affine.about(pivot, _Affine.rotation(angle)))
        .toMatrix4();
  }

  static void _cape(Canvas canvas, HeroMarkColors colors, HeroMarkPose pose) {
    final cape = Paint()..color = colors.cape;
    if (pose._restingCape) {
      canvas.drawPath(HeroMark.capeWithGap, cape);
      return;
    }
    final shape = HeroMark.capeShape(wave: pose.wave, phase: pose.phase);
    canvas
      ..save()
      ..clipPath(HeroMark.outsideGap)
      ..drawPath(shape.outline, cape);
    if (pose.fold > 0) {
      final under = colors.capeUnderside;
      canvas.drawPath(
        shape.underside,
        Paint()..color = under.withValues(alpha: under.a * pose.fold),
      );
    }
    canvas.restore();
  }
}

/// A 2D affine transform `(x, y) → (a·x + c·y + tx, b·x + d·y + ty)`.
@immutable
class _Affine {
  const _Affine(this.a, this.b, this.c, this.d, this.tx, this.ty);

  _Affine.translation(Offset o) : this(1, 0, 0, 1, o.dx, o.dy);

  const _Affine.scaling(double sx, double sy) : this(sx, 0, 0, sy, 0, 0);

  factory _Affine.rotation(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return _Affine(cos, sin, -sin, cos, 0, 0);
  }

  /// [inner] applied about [point] instead of the origin.
  factory _Affine.about(Offset point, _Affine inner) =>
      _Affine.translation(point) * inner * _Affine.translation(-point);

  final double a, b, c, d, tx, ty;

  /// This after [other]: `(this * other)(p) == this(other(p))`.
  _Affine operator *(_Affine other) => _Affine(
    a * other.a + c * other.b,
    b * other.a + d * other.b,
    a * other.c + c * other.d,
    b * other.c + d * other.d,
    a * other.tx + c * other.ty + tx,
    b * other.tx + d * other.ty + ty,
  );

  /// Column-major 4×4, as `Canvas.transform` and `Path.transform` take it.
  Float64List toMatrix4() => Float64List.fromList([
    a, b, 0, 0, //
    c, d, 0, 0, //
    0, 0, 1, 0, //
    tx, ty, 0, 1, //
  ]);
}
