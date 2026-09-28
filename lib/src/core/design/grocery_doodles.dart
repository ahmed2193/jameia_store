import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../config/theme/app_colors.dart';

/// Flat, top-down groceries — the spread the brand header is set on, like
/// food laid out on a table around the logo. Each one is built from plain
/// shapes in a [GroceryDoodlePainting.box]-unit square centred on
/// [GroceryDoodlePainting.center], in the app's own colours, so a painter
/// only scales, turns and places it.
enum GroceryDoodle {
  orange,
  lemon,
  milk,
  coffee,
  chocolate,
  avocado,
  egg,
  croissant,
  grapes,
  carrot,
  donut,
  greens,
}

/// Draws a [GroceryDoodle] over a soft contact shadow. Shapes and paints are
/// built once (they are the same for every picture recorded from them).
abstract final class GroceryDoodlePainting {
  /// Side of the design square every doodle is drawn in, and its centre.
  static const double box = 100;
  static const Offset center = Offset(box / 2, box / 2);

  /// Where the contact shadow falls (design units) and how dark it is.
  static const Offset shadowOffset = Offset(3, 6);
  static const double shadowOpacity = 0.14;

  static void paint(Canvas canvas, GroceryDoodle doodle) {
    final silhouette = _silhouettes[doodle];
    if (silhouette != null) {
      canvas
        ..save()
        ..translate(shadowOffset.dx, shadowOffset.dy)
        ..drawPath(silhouette, _shadow)
        ..restore();
    }
    for (final (path, paint) in _layers[doodle]!) {
      canvas.drawPath(path, paint);
    }
  }

  // ── Paints ────────────────────────────────────────────────────────────────
  static final Paint _shadow = _fill(
    AppColors.black.withValues(alpha: shadowOpacity),
  );
  static final Paint _white = _fill(AppColors.white);
  static final Paint _orangeInk = _fill(AppColors.accent3);
  static final Paint _orangeLight = _fill(
    AppColors.orange[4].withValues(alpha: 0.7),
  );
  static final Paint _yellow = _fill(AppColors.accent4);
  static final Paint _yellowLight = _fill(AppColors.accent4Light);
  static final Paint _amber = _fill(AppColors.proAmber);
  static final Paint _lime = _fill(AppColors.proLime);
  static final Paint _brown = _fill(AppColors.voucherBrown);
  static final Paint _brownLight = _fill(AppColors.orange[12]);
  static final Paint _pit = _fill(AppColors.skuOptionFg);
  static final Paint _pitShine = _fill(
    AppColors.orange[12].withValues(alpha: 0.7),
  );
  static final Paint _brand = _fill(AppColors.primary);
  static final Paint _brandPale = _fill(AppColors.brandLightBg);
  static final Paint _leaf = _fill(AppColors.brandDeep);
  static final Paint _leafLight = _fill(AppColors.primaryDark);
  static final Paint _avocadoSkin = _fill(AppColors.green[11]);
  static final Paint _saucerWell = _fill(AppColors.smallBackground);
  static final Paint _grape = _fill(AppColors.accentViolet);
  static final Paint _grapeShine = _fill(
    AppColors.accentVioletLight.withValues(alpha: 0.6),
  );
  static final Paint _icing = _fill(AppColors.magenta[3]);
  static final Paint _crema = _stroke(AppColors.orange[12], 3);
  static final Paint _foam = _stroke(kHeroPromoCream.withValues(alpha: 0.8), 3);
  static final Paint _crust = _stroke(AppColors.accent3, 3);
  static final Paint _ridge = _stroke(AppColors.accent3Dark, 3);
  static final Paint _stem = _stroke(AppColors.brandDeep, 4);
  static final Paint _stemThin = _stroke(AppColors.brandDeep, 3.5);
  static final Paint _tops = _stroke(AppColors.brandDeep, 6);

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  // ── Orange ────────────────────────────────────────────────────────────────
  static final Path _orangeBody = _circle(50, 52, 34);
  static final Path _orangeLeaf = _oval(61, 16, 11, 5, -25);

  // ── Lemon slice ───────────────────────────────────────────────────────────
  static final Path _lemonRind = _circle(50, 50, 36);
  static final Path _lemonSegments = () {
    const count = 8;
    const radius = 27.0;
    const inset = 3.0;
    const gap = 0.06;
    final path = Path();
    for (var i = 0; i < count; i++) {
      final from = 2 * math.pi * i / count + gap;
      final sweep = 2 * math.pi / count - 2 * gap;
      final middle = from + sweep / 2;
      path
        ..moveTo(50 + inset * math.cos(middle), 50 + inset * math.sin(middle))
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          from,
          sweep,
          false,
        )
        ..close();
    }
    return path;
  }();

  // ── Milk bottle ───────────────────────────────────────────────────────────
  static final Path _milkBody = _rounded(33, 30, 34, 62, 12);
  static final Path _milkNeck = Path()
    ..moveTo(40, 31)
    ..lineTo(40, 18)
    ..quadraticBezierTo(40, 14, 44, 14)
    ..lineTo(56, 14)
    ..quadraticBezierTo(60, 14, 60, 18)
    ..lineTo(60, 31)
    ..close();
  static final Path _milkCap = _rounded(40.5, 6, 19, 10, 3);

  // ── Coffee cup on its saucer ──────────────────────────────────────────────
  static final Path _saucer = _circle(46, 52, 40);
  static final Path _cupHandle = _rounded(68, 45, 26, 14, 7);
  static final Path _coffee = _circle(46, 52, 22);
  static final Path _foamSwirl = Path()
    ..moveTo(38, 48)
    ..quadraticBezierTo(46, 42, 54, 48);

  // ── Chocolate bar ─────────────────────────────────────────────────────────
  static final Path _chocolateBar = _rounded(28, 8, 44, 86, 6);
  static final Path _chocolateSquares = () {
    final path = Path();
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 2; column++) {
        path.addPath(
          _rounded(31 + column * 20.0, 36 + row * 14.0, 17, 11, 2),
          Offset.zero,
        );
      }
    }
    return path;
  }();
  static final Path _chocolateFoil = () {
    final path = Path()
      ..moveTo(26, 6)
      ..lineTo(74, 6)
      ..lineTo(74, 32);
    var down = false;
    for (var x = 70.0; x >= 26; x -= 4) {
      path.lineTo(x, down ? 32 : 27);
      down = !down;
    }
    return path..close();
  }();
  static final Path _chocolateBand = _rect(26, 12, 48, 6);

  // ── Avocado half ──────────────────────────────────────────────────────────
  static final Path _avocadoOuter = _egg(50, 6, 96, 30, 20);
  static final Path _avocadoFlesh = _egg(50, 13, 89, 23, 17);

  // ── Fried egg ─────────────────────────────────────────────────────────────
  static final Path _eggWhite = Path()
    ..moveTo(50, 12)
    ..cubicTo(66, 10, 84, 22, 86, 40)
    ..cubicTo(88, 56, 80, 64, 84, 76)
    ..cubicTo(88, 90, 66, 94, 52, 90)
    ..cubicTo(38, 86, 24, 92, 16, 80)
    ..cubicTo(8, 68, 18, 58, 14, 44)
    ..cubicTo(10, 28, 32, 14, 50, 12)
    ..close();

  // ── Croissant ─────────────────────────────────────────────────────────────
  static final Path _croissantBody = Path()
    ..moveTo(10, 62)
    ..cubicTo(14, 40, 34, 22, 50, 22)
    ..cubicTo(66, 22, 86, 40, 90, 62)
    ..cubicTo(80, 58, 74, 60, 70, 66)
    ..cubicTo(66, 54, 58, 48, 50, 48)
    ..cubicTo(42, 48, 34, 54, 30, 66)
    ..cubicTo(26, 60, 20, 58, 10, 62)
    ..close();
  static final Path _croissantFolds = Path()
    ..moveTo(42, 24)
    ..cubicTo(44, 34, 44, 40, 42, 46)
    ..moveTo(58, 24)
    ..cubicTo(56, 34, 56, 40, 58, 46)
    ..moveTo(26, 34)
    ..cubicTo(30, 42, 32, 48, 32, 56)
    ..moveTo(74, 34)
    ..cubicTo(70, 42, 68, 48, 68, 56);

  // ── Grapes ────────────────────────────────────────────────────────────────
  static const List<Offset> _grapeAt = [
    Offset(40, 34),
    Offset(56, 34),
    Offset(32, 48),
    Offset(48, 48),
    Offset(64, 48),
    Offset(40, 62),
    Offset(56, 62),
    Offset(48, 76),
  ];
  static final Path _grapeStem = Path()
    ..moveTo(50, 30)
    ..quadraticBezierTo(52, 16, 62, 10);
  static final Path _grapeLeaf = _oval(64, 20, 12, 7, -30);
  static final Path _grapeBerries = _union([
    for (final at in _grapeAt) _circle(at.dx, at.dy, 9.5),
  ]);
  static final Path _grapeShines = _union([
    for (final at in _grapeAt) _circle(at.dx - 3, at.dy - 3, 3),
  ]);

  // ── Carrot ────────────────────────────────────────────────────────────────
  static final Path _carrotRoot = Path()
    ..moveTo(44, 30)
    ..quadraticBezierTo(50, 26, 56, 30)
    ..lineTo(54, 92)
    ..quadraticBezierTo(50, 98, 46, 92)
    ..close();
  static final Path _carrotRidges = Path()
    ..moveTo(45, 44)
    ..lineTo(50, 46)
    ..moveTo(47, 58)
    ..lineTo(53, 60)
    ..moveTo(46, 72)
    ..lineTo(51, 74);
  static final Path _carrotTops = Path()
    ..moveTo(50, 30)
    ..cubicTo(44, 18, 36, 12, 30, 10)
    ..moveTo(50, 30)
    ..cubicTo(50, 18, 50, 10, 50, 4)
    ..moveTo(50, 30)
    ..cubicTo(56, 18, 64, 12, 70, 10);

  // ── Doughnut ──────────────────────────────────────────────────────────────
  static final Path _donutHole = _circle(50, 50, 12);
  static final Path _donutRing = Path.combine(
    PathOperation.difference,
    _circle(50, 50, 38),
    _donutHole,
  );
  static final Path _donutIcing = Path.combine(
    PathOperation.difference,
    Path()
      ..moveTo(50, 16)
      ..cubicTo(62, 14, 80, 22, 84, 40)
      ..cubicTo(86, 50, 80, 54, 84, 62)
      ..cubicTo(82, 76, 66, 86, 50, 86)
      ..cubicTo(36, 86, 20, 78, 16, 62)
      ..cubicTo(20, 54, 14, 48, 18, 38)
      ..cubicTo(22, 24, 38, 16, 50, 16)
      ..close(),
    _circle(50, 50, 14),
  );
  static final Path _sprinklesLight = _union([
    _sprinkle(36, 32, 20),
    _sprinkle(64, 68, 10),
    _sprinkle(28, 52, 80),
    _sprinkle(70, 46, 60),
  ]);
  static final Path _sprinklesYellow = _union([
    _sprinkle(58, 28, -30),
    _sprinkle(40, 72, -40),
  ]);

  // ── Sprig of greens ───────────────────────────────────────────────────────
  static final Path _sprigStem = Path()
    ..moveTo(50, 94)
    ..quadraticBezierTo(50, 60, 50, 10);
  static final Path _sprigLeaves = _union([
    _oval(50, 18, 8, 14, 0),
    _oval(36, 58, 8, 14, -45),
    _oval(64, 58, 8, 14, 45),
  ]);
  static final Path _sprigLeavesLight = _union([
    _oval(38, 36, 8, 14, -40),
    _oval(62, 36, 8, 14, 40),
    _oval(40, 78, 8, 14, -50),
    _oval(60, 78, 8, 14, 50),
  ]);

  // ── What each doodle paints, bottom layer first ──────────────────────────
  static final Map<GroceryDoodle, List<(Path, Paint)>> _layers = {
    GroceryDoodle.orange: [
      (_orangeBody, _orangeInk),
      (_circle(39, 40, 12), _orangeLight),
      (_circle(50, 20, 3), _pit),
      (_orangeLeaf, _leaf),
    ],
    GroceryDoodle.lemon: [
      (_lemonRind, _amber),
      (_circle(50, 50, 31.5), _yellowLight),
      (_lemonSegments, _yellow),
    ],
    GroceryDoodle.milk: [
      (_milkBody, _white),
      (_milkNeck, _white),
      (_milkCap, _brand),
      (_rect(33, 52, 34, 20), _brandPale),
      (_rounded(40, 59, 20, 6, 3), _brand),
    ],
    GroceryDoodle.coffee: [
      (_saucer, _white),
      (_circle(46, 52, 33), _saucerWell),
      (_cupHandle, _white),
      (_circle(46, 52, 27), _white),
      (_coffee, _brown),
      (_coffee, _crema),
      (_foamSwirl, _foam),
    ],
    GroceryDoodle.chocolate: [
      (_chocolateBar, _brown),
      (_chocolateSquares, _brownLight),
      (_chocolateFoil, _yellow),
      (_chocolateBand, _amber),
    ],
    GroceryDoodle.avocado: [
      (_avocadoOuter, _avocadoSkin),
      (_avocadoFlesh, _lime),
      (_circle(50, 62, 16), _pit),
      (_circle(45, 57, 5), _pitShine),
    ],
    GroceryDoodle.egg: [
      (_eggWhite, _white),
      (_circle(50, 52, 17), _amber),
      (_circle(44, 46, 5), _yellow),
    ],
    GroceryDoodle.croissant: [
      (_croissantBody, _amber),
      (_croissantFolds, _crust),
    ],
    GroceryDoodle.grapes: [
      (_grapeStem, _stem),
      (_grapeLeaf, _leafLight),
      (_grapeBerries, _grape),
      (_grapeShines, _grapeShine),
    ],
    GroceryDoodle.carrot: [
      (_carrotTops, _tops),
      (_carrotRoot, _orangeInk),
      (_carrotRidges, _ridge),
    ],
    GroceryDoodle.donut: [
      (_donutRing, _amber),
      (_donutIcing, _icing),
      (_sprinklesLight, _white),
      (_sprinklesYellow, _yellow),
    ],
    GroceryDoodle.greens: [
      (_sprigStem, _stemThin),
      (_sprigLeaves, _leaf),
      (_sprigLeavesLight, _leafLight),
    ],
  };

  /// The outline each doodle's shadow takes; the sprig casts none (dark
  /// leaves on the green read without one).
  static final Map<GroceryDoodle, Path> _silhouettes = {
    GroceryDoodle.orange: _orangeBody,
    GroceryDoodle.lemon: _lemonRind,
    GroceryDoodle.milk: _union([_milkBody, _milkNeck, _milkCap]),
    GroceryDoodle.coffee: _union([_saucer, _cupHandle]),
    GroceryDoodle.chocolate: _union([_chocolateBar, _rect(26, 6, 48, 27)]),
    GroceryDoodle.avocado: _avocadoOuter,
    GroceryDoodle.egg: _eggWhite,
    GroceryDoodle.croissant: _croissantBody,
    GroceryDoodle.grapes: _union([_grapeBerries, _grapeLeaf]),
    GroceryDoodle.carrot: _carrotRoot,
    GroceryDoodle.donut: _donutRing,
  };

  // ── Shape helpers (design units) ──────────────────────────────────────────
  static Path _circle(double x, double y, double radius) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));

  static Path _rect(double x, double y, double width, double height) =>
      Path()..addRect(Rect.fromLTWH(x, y, width, height));

  static Path _rounded(
    double x,
    double y,
    double width,
    double height,
    double corner,
  ) => Path()
    ..addRRect(
      RRect.fromRectXY(Rect.fromLTWH(x, y, width, height), corner, corner),
    );

  /// An ellipse of radii [rx] × [ry] centred on ([x], [y]), turned [degrees].
  static Path _oval(double x, double y, double rx, double ry, double degrees) {
    final shape = Path()
      ..addOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      );
    final turn = degrees * math.pi / 180;
    final c = math.cos(turn);
    final s = math.sin(turn);
    return shape.transform(
      Float64List.fromList([
        c, s, 0, 0, //
        -s, c, 0, 0, //
        0, 0, 1, 0, //
        x, y, 0, 1, //
      ]),
    );
  }

  /// A pear-shaped outline from [top] to [bottom] on the centre line [x]:
  /// [waist] half-width near the top, [belly] half-width low down.
  static Path _egg(
    double x,
    double top,
    double bottom,
    double belly,
    double waist,
  ) {
    final height = bottom - top;
    final waistY = top + height * 0.27;
    final bellyY = top + height * 0.5;
    return Path()
      ..moveTo(x, top)
      ..cubicTo(
        x + waist * 0.8,
        top,
        x + waist * 1.2,
        waistY,
        x + belly,
        bellyY,
      )
      ..cubicTo(
        x + belly * 1.25,
        top + height * 0.8,
        x + belly * 0.7,
        bottom,
        x,
        bottom,
      )
      ..cubicTo(
        x - belly * 0.7,
        bottom,
        x - belly * 1.25,
        top + height * 0.8,
        x - belly,
        bellyY,
      )
      ..cubicTo(x - waist * 1.2, waistY, x - waist * 0.8, top, x, top)
      ..close();
  }

  /// A sprinkle (a short rounded bar) centred on ([x], [y]), turned [degrees].
  static Path _sprinkle(double x, double y, double degrees) {
    const length = 8.0;
    const thickness = 3.0;
    final turn = degrees * math.pi / 180;
    final c = math.cos(turn);
    final s = math.sin(turn);
    return (Path()..addRRect(
          RRect.fromRectXY(
            Rect.fromCenter(
              center: Offset.zero,
              width: length,
              height: thickness,
            ),
            thickness / 2,
            thickness / 2,
          ),
        ))
        .transform(
          Float64List.fromList([
            c, s, 0, 0, //
            -s, c, 0, 0, //
            0, 0, 1, 0, //
            x, y, 0, 1, //
          ]),
        );
  }

  static Path _union(List<Path> paths) => paths
      .skip(1)
      .fold(
        paths.first,
        (union, path) => Path.combine(PathOperation.union, union, path),
      );
}
