import 'dart:ui';

import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_palette.dart';
import 'splash_wordmark_geometry.dart';
import 'splash_wordmark_glyphs.dart';

/// Draws the name of the lockup — letters, swoosh, stripes and leaf — as far
/// as the [SplashFrame] has revealed them.
abstract final class SplashWordmarkPainting {
  /// Letters before this index are "ameia" ([SplashPalette.letterInk]), the
  /// rest "Mart" ([SplashPalette.letterAccent]).
  static const int martStart = 5;

  /// A letter rises from this far under the baseline and grows from
  /// [letterStartScale] as it springs in.
  static const double letterRise = 260;
  static const double letterStartScale = 0.55;

  /// A letter is fully opaque once its spring is this far along.
  static const double letterOpaqueAt = 0.6;

  /// Stripe lean (x shift per unit of height) and the height they span.
  static const double stripeLean = 0.08;
  static const double stripeReach = 900;

  /// Extra turn of the leaf while it grows, in radians.
  static const double leafUnfurl = 0.6;

  /// Half width of the light band sweeping the name, its peak opacity, and
  /// the margin of the layer it is clipped to (font units).
  static const double shineHalfWidth = 520;
  static const double shineOpacity = 0.75;
  static const double shineMargin = 120;

  /// Top of the shine layer: above the leaf's tip.
  static const double shineTop = -1100;

  static final List<Rect> _letterBounds = [
    for (final letter in SplashWordmarkGlyphs.letters) letter.getBounds(),
  ];

  static void paint(
    Canvas canvas,
    SplashLayout layout,
    SplashFrame frame,
    SplashPalette palette,
  ) {
    canvas
      ..save()
      ..translate(layout.textOrigin.dx, layout.textOrigin.dy)
      ..scale(layout.scale);
    final shining = frame.shine > 0 && frame.shine < 1;
    // While the light sweeps, the name is drawn into its own layer so the
    // band only lights the letters, swoosh and leaf (srcATop).
    if (shining) canvas.saveLayer(_shineBounds, Paint());
    if (frame.swoosh > 0) _swoosh(canvas, frame, palette);
    _letters(canvas, frame, palette);
    if (frame.leaf > 0) _leaf(canvas, frame, palette);
    if (shining) {
      _shine(canvas, frame, palette);
      canvas.restore();
    }
    canvas.restore();
  }

  static final Rect _shineBounds = Rect.fromLTRB(
    SplashWordmarkGeometry.swooshStart.dx - shineMargin,
    shineTop,
    SplashWordmarkGlyphs.width + shineMargin,
    SplashWordmarkGeometry.swooshBounds.bottom + shineMargin,
  );

  static void _shine(Canvas canvas, SplashFrame frame, SplashPalette palette) {
    final bounds = _shineBounds;
    final x =
        bounds.left -
        shineHalfWidth +
        frame.shine * (bounds.width + 2 * shineHalfWidth);
    final light = palette.shine;
    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = Gradient.linear(
          Offset(x - shineHalfWidth, bounds.top),
          Offset(x + shineHalfWidth, bounds.bottom),
          [
            light.withValues(alpha: 0),
            light.withValues(alpha: light.a * shineOpacity),
            light.withValues(alpha: 0),
          ],
          const [0, 0.5, 1],
        ),
    );
  }

  static void _letters(
    Canvas canvas,
    SplashFrame frame,
    SplashPalette palette,
  ) {
    final letters = SplashWordmarkGlyphs.letters;
    for (var i = 0; i < frame.letters.length && i < letters.length; i++) {
      final spring = frame.letters[i];
      if (spring <= 0) continue;
      // Each letter springs in tinted and settles to its own colour.
      final settled = i < martStart ? palette.letterInk : palette.letterAccent;
      final color =
          Color.lerp(palette.letterFlash, settled, spring.clamp(0.0, 1.0)) ??
          settled;
      final alpha = (spring / letterOpaqueAt).clamp(0.0, 1.0);
      final pivotX = _letterBounds[i].center.dx;
      final scale = letterStartScale + (1 - letterStartScale) * spring;
      canvas
        ..save()
        ..translate(pivotX, (1 - spring) * letterRise)
        ..scale(scale)
        ..translate(-pivotX, 0)
        ..drawPath(
          letters[i],
          Paint()..color = color.withValues(alpha: color.a * alpha),
        )
        ..restore();
    }
  }

  static void _swoosh(Canvas canvas, SplashFrame frame, SplashPalette palette) {
    const start = SplashWordmarkGeometry.swooshStart;
    final shape = SplashWordmarkGeometry.swoosh;
    final bounds = SplashWordmarkGeometry.swooshBounds;
    final drawn =
        start.dx +
        frame.swoosh * (SplashWordmarkGeometry.swooshRight - start.dx);
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(bounds.left, bounds.top, drawn, bounds.bottom))
      ..drawPath(shape, Paint()..color = palette.swoosh);
    if (frame.stripes > 0) {
      canvas.clipPath(shape);
      final stripe = Paint()..color = palette.stripe;
      final half = SplashWordmarkGeometry.stripeWidth / 2 * frame.stripes;
      const lean = stripeLean * stripeReach;
      for (final x in SplashWordmarkGeometry.stripeCenters) {
        canvas.drawPath(
          Path()
            ..moveTo(x - half + lean, bounds.top)
            ..lineTo(x + half + lean, bounds.top)
            ..lineTo(x + half - lean, bounds.top + stripeReach)
            ..lineTo(x - half - lean, bounds.top + stripeReach)
            ..close(),
          stripe,
        );
      }
    }
    canvas.restore();
  }

  static void _leaf(Canvas canvas, SplashFrame frame, SplashPalette palette) {
    const base = SplashWordmarkGeometry.leafBase;
    canvas
      ..save()
      ..translate(base.dx, base.dy)
      ..rotate(SplashWordmarkGeometry.leafTilt - (1 - frame.leaf) * leafUnfurl)
      ..scale(frame.leaf)
      ..drawPath(SplashWordmarkGeometry.leaf, Paint()..color = palette.leaf)
      ..drawLine(
        SplashWordmarkGeometry.veinStart,
        SplashWordmarkGeometry.veinEnd,
        Paint()
          ..color = palette.background
          ..strokeWidth = SplashWordmarkGeometry.leafVeinWidth
          ..strokeCap = StrokeCap.round,
      )
      ..restore();
  }
}
