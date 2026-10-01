import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'hero_glyphs.dart';

/// The Hero mark: a shopping bag wearing a cape, the everyday grocery hero,
/// with the "h" of the name on its front. Plain shapes in a 100-unit design
/// square (y down); the whole mark tips back by [tilt] about [pivot], nose up,
/// as if climbing into flight.
///
/// Every place the brand shows draws from these shapes: the splash, the
/// native launch images and app icons (`tool/splash/`) and the Home tab's
/// `HeroMarkIcon`. So the first Flutter frame repeats the OS splash, and the
/// Home tab repeats the launcher icon.
abstract final class HeroMark {
  // ── Bag ────────────────────────────────────────────────────────────────────
  static const Offset bagTopLeft = Offset(36, 40);
  static const Offset bagTopRight = Offset(80, 40);
  static const Offset bagBottomRight = Offset(83.5, 88);
  static const Offset bagBottomLeft = Offset(32.5, 88);
  static const double bagTopCorner = 4;
  static const double bagBottomCorner = 8;

  // ── Handle: a half-ellipse arch standing on the bag ────────────────────────
  /// Centre of the arch's base, its centre-line radii and its thickness.
  static const Offset handleBase = Offset(58, 42);
  static const double handleRadiusX = 10;
  static const double handleRadiusY = 17;
  static const double handleThickness = 6.5;

  // ── Cape ───────────────────────────────────────────────────────────────────
  /// Where the cape is tied: a vertical edge behind the bag's top-left corner.
  static const double capeTieX = 40;
  static const double capeTieTop = 41;
  static const double capeTieBottom = 52;

  /// How far back the cape flows, how tall its tail flares and how much the
  /// wind lifts it (negative = up).
  static const double capeLength = 36;
  static const double capeTailHeight = 40;
  static const double capeLift = -1;

  /// Waves along the cape, the points of its scalloped tail and how deep the
  /// scallops cut in.
  static const double capeWaves = 1.2;
  static const int capeTips = 3;
  static const double capeTipDepth = 5;

  /// The cape's wave at rest (amplitude, design units) and where along the
  /// wave it rests (radians). The icons and the launch image show this pose.
  static const double restWave = 3;
  static const double restPhase = 0.6;

  /// Share of the cape's height, from the top, where its darker underside
  /// shows when it twists in flight.
  static const double undersideFrom = 0.6;
  static const int _capeSteps = 20;

  // ── Pose ───────────────────────────────────────────────────────────────────
  /// Tilt of the whole mark about [pivot], the middle of the bag (radians;
  /// negative tips it back, nose up, like a hero climbing).
  static const double tilt = -8 * math.pi / 180;
  static const Offset pivot = Offset(58, 64);

  /// Gap cut between the cape and the bag, so the bag stands in front.
  static const double gap = 1.8;

  static final Path bag = _roundedQuad(
    const [bagTopLeft, bagTopRight, bagBottomRight, bagBottomLeft],
    const [bagTopCorner, bagTopCorner, bagBottomCorner, bagBottomCorner],
  );

  /// The bag with the emblem cut out of it (the "h" shows what is behind).
  static final Path bagWithEmblem = Path.combine(
    PathOperation.difference,
    bag,
    HeroGlyphs.emblem,
  );

  /// The handle as a filled arch, open at its base (the bag covers it).
  static final Path handle = () {
    const half = handleThickness / 2;
    const outer = Radius.elliptical(handleRadiusX + half, handleRadiusY + half);
    const inner = Radius.elliptical(handleRadiusX - half, handleRadiusY - half);
    const b = handleBase;
    return Path()
      ..moveTo(b.dx - outer.x, b.dy)
      ..arcToPoint(Offset(b.dx + outer.x, b.dy), radius: outer)
      ..lineTo(b.dx + inner.x, b.dy)
      ..arcToPoint(
        Offset(b.dx - inner.x, b.dy),
        radius: inner,
        clockwise: false,
      )
      ..close();
  }();

  /// The bag's outline pushed out by [gap]: the cape is cut away inside it.
  static final Path _gapOutline = _roundedQuad(
    const [bagTopLeft, bagTopRight, bagBottomRight, bagBottomLeft],
    const [bagTopCorner, bagTopCorner, bagBottomCorner, bagBottomCorner],
    inflate: gap,
  );

  /// Everything outside the bag's gap outline: clip the cape with it.
  static final Path outsideGap = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(const Rect.fromLTRB(-100, -100, 200, 200))
    ..addPath(_gapOutline, Offset.zero);

  /// The cape at rest, and with the gap already cut (for one-colour art).
  static final Path capeAtRest = capeShape().outline;
  static final Path capeWithGap = Path.combine(
    PathOperation.difference,
    capeAtRest,
    _gapOutline,
  );

  /// The cape flowing back from its tie, rippled by a travelling wave of
  /// [wave] units at [phase] radians: its [outline] and the darker
  /// [underside] that shows as the cloth twists. The wave grows towards the
  /// tail, so the tie stays put while the tips flutter.
  static ({Path outline, Path underside}) capeShape({
    double wave = restWave,
    double phase = restPhase,
  }) {
    const tieHeight = capeTieBottom - capeTieTop;
    const tieMiddle = (capeTieTop + capeTieBottom) / 2;
    final top = <Offset>[];
    final bottom = <Offset>[];
    final fold = <Offset>[];
    for (var i = 0; i <= _capeSteps; i++) {
      final t = i / _capeSteps;
      final x = capeTieX - capeLength * t;
      final middle =
          tieMiddle +
          capeLift * t +
          wave * math.sin(2 * math.pi * capeWaves * t - phase) * t;
      final height =
          tieHeight + (capeTailHeight - tieHeight) * math.pow(t, 0.8);
      top.add(Offset(x, middle - height / 2));
      bottom.add(Offset(x, middle + height / 2));
      fold.add(Offset(x, middle - height / 2 + height * undersideFrom));
    }
    final tailTop = top.last;
    final tailBottom = bottom.last;
    final outline = Path()..moveTo(top.first.dx, top.first.dy);
    _smoothThrough(outline, top);
    for (var i = 0; i < capeTips - 1; i++) {
      final from = Offset.lerp(tailTop, tailBottom, i / (capeTips - 1))!;
      final to = Offset.lerp(tailTop, tailBottom, (i + 1) / (capeTips - 1))!;
      // Each scallop curves in towards the tie, leaving the tips pointed.
      final dip = (from + to) / 2 + const Offset(2 * capeTipDepth, 0);
      outline.quadraticBezierTo(dip.dx, dip.dy, to.dx, to.dy);
    }
    final back = bottom.reversed.toList();
    _smoothThrough(outline, back);
    outline.close();
    final underside = Path()..moveTo(fold.first.dx, fold.first.dy);
    _smoothThrough(underside, fold);
    underside.lineTo(tailBottom.dx, tailBottom.dy);
    _smoothThrough(underside, back);
    underside.close();
    return (outline: outline, underside: underside);
  }

  // ── Where things are (tilt included) ───────────────────────────────────────
  /// The tilt as a path transform (about [pivot]).
  static final Float64List tiltMatrix = () {
    final c = math.cos(tilt);
    final s = math.sin(tilt);
    final tx = pivot.dx - pivot.dx * c + pivot.dy * s;
    final ty = pivot.dy - pivot.dx * s - pivot.dy * c;
    return Float64List.fromList([
      c, s, 0, 0, //
      -s, c, 0, 0, //
      0, 0, 1, 0, //
      tx, ty, 0, 1, //
    ]);
  }();

  /// [point] of the upright mark after the tilt.
  static Offset tilted(Offset point) {
    final c = math.cos(tilt);
    final s = math.sin(tilt);
    final d = point - pivot;
    return pivot + Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
  }

  /// The resting mark as one outline (bag, handle, cape), tilted.
  static final Path _silhouette =
      (Path()
            ..addPath(bag, Offset.zero)
            ..addPath(handle, Offset.zero)
            ..addPath(capeAtRest, Offset.zero))
          .transform(tiltMatrix);

  /// Painted extent of the resting mark, tilt included.
  static final Rect bounds = _silhouette.getBounds();

  /// Farthest painted point from the centre of [bounds]: what must fit
  /// inside the circle Android keeps of a launch or adaptive icon.
  static final double reach = () {
    final c = bounds.center;
    var far = 0.0;
    for (final metric in _silhouette.computeMetrics()) {
      for (var d = 0.0; d <= metric.length; d += 0.5) {
        final at = metric.getTangentForOffset(d)?.position;
        if (at != null) far = math.max(far, (at - c).distance);
      }
    }
    return far;
  }();

  /// Middle of the bag's bottom edge: where the mark stands (squash pivot,
  /// landing rings).
  static final Offset ground = tilted(
    Offset((bagBottomLeft.dx + bagBottomRight.dx) / 2, bagBottomLeft.dy),
  );

  /// Middle of the bag's opening: where its deliveries come out.
  static final Offset opening = tilted(
    Offset((bagTopLeft.dx + bagTopRight.dx) / 2, bagTopLeft.dy),
  );

  /// Middle of the bag itself (the cape left out).
  static final Offset bagCenter = tilted(pivot);

  // ── Helpers ────────────────────────────────────────────────────────────────
  /// A convex polygon with rounded corners (a quadratic curve per corner),
  /// optionally pushed out by [inflate] on every side.
  static Path _roundedQuad(
    List<Offset> corners,
    List<double> radii, {
    double inflate = 0,
  }) {
    final n = corners.length;
    final points = <Offset>[
      for (var i = 0; i < n; i++)
        _pushedOut(
          corners[(i + n - 1) % n],
          corners[i],
          corners[(i + 1) % n],
          inflate,
        ),
    ];
    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final prev = points[(i + n - 1) % n];
      final next = points[(i + 1) % n];
      final r = radii[i] + inflate;
      final a = p + _unit(prev - p) * r;
      final b = p + _unit(next - p) * r;
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
    }
    return path..close();
  }

  /// Corner [p] moved out by [d] along both of its edges' outward normals
  /// (corners run clockwise on screen).
  static Offset _pushedOut(Offset prev, Offset p, Offset next, double d) {
    if (d == 0) return p;
    final n1 = _normal(p - prev);
    final n2 = _normal(next - p);
    final dot = n1.dx * n2.dx + n1.dy * n2.dy;
    return p + (n1 + n2) * (d / (1 + dot));
  }

  static Offset _normal(Offset edge) {
    final u = _unit(edge);
    return Offset(u.dy, -u.dx);
  }

  static Offset _unit(Offset v) => v / v.distance;

  /// Continues [path] from `points.first` through every point (Catmull-Rom
  /// as cubic curves).
  static void _smoothThrough(Path path, List<Offset> points) {
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(points.length - 1, i + 2)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
  }
}
