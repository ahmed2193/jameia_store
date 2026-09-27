import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../../../../config/theme/app_colors.dart';
import 'assistant_mascot_geometry.dart';
import 'assistant_mascot_pose.dart';

/// Draws the assistant mascot — a brand-green gumdrop with a sprout on top
/// (fresh groceries) and a sparkle beside it (the assistant) — in [pose].
///
/// The design is set in units of the drawing's width (the constants below)
/// and drawn in pixels: fixed shapes come from [AssistantMascotGeometry]
/// (built once per size), the face is a handful of ovals and strokes. The
/// canvas is only ever moved, turned or squashed a little — never scaled up
/// from a unit square, which some GPU back ends cannot take. [outlined] adds
/// a white sticker rim so the mascot reads over any content (the floating
/// launcher); the chat rows sit on white and skip it.
class AssistantMascotPainter extends CustomPainter {
  const AssistantMascotPainter({required this.pose, this.outlined = false});

  final AssistantMascotPose pose;
  final bool outlined;

  // ── Fit ────────────────────────────────────────────────────────────────
  // The drawing (sprout, rim and a full stretch included) spans a little
  // more than its unit square; this brings all of it inside the canvas.
  static const double _fit = 0.89;
  static const Offset _fitShift = Offset(0.055, 0.089);

  // ── Body ───────────────────────────────────────────────────────────────
  static const Offset _feet = Offset(0.5, 0.94);
  static const double _squashX = 0.08;
  static const double _squashY = 0.1;

  // ── Gloss + cheeks ─────────────────────────────────────────────────────
  static const Offset _gloss = Offset(0.32, 0.36);
  static const double _glossW = 0.17;
  static const double _glossH = 0.08;
  static const double _glossTilt = -0.55;
  static const double _glossAlpha = 0.38;

  static const int _blushShade = 3;
  static const double _cheekX = 0.25;
  static const double _cheekY = 0.66;
  static const double _cheekW = 0.1;
  static const double _cheekH = 0.052;
  static const double _cheekAlpha = 0.72;
  static const double _cheekHappyAlpha = 0.28;

  // ── Face ───────────────────────────────────────────────────────────────
  static const double _eyeX = 0.13;
  static const double _eyeY = 0.565;
  static const double _eyeW = 0.085;
  static const double _eyeH = 0.125;
  static const double _eyeMinH = 0.012;
  static const double _surpriseGrow = 0.3;
  static const double _glint = 0.019;
  static const Offset _glintAt = Offset(0.016, -0.03);
  static const double _lookX = 0.04;
  static const double _lookY = 0.028;
  static const double _cheekFollow = 0.5;

  static const double _arcHalf = 0.048;
  static const double _arcRise = 0.042;
  static const double _arcDrop = 0.012;
  static const double _stroke = 0.03;

  static const double _mouthY = 0.7;
  static const double _smileHalf = 0.052;
  static const double _smileWiden = 0.02;
  static const double _smileDip = 0.035;
  static const double _smileDipHappy = 0.035;
  static const double _openFrom = 0.08;
  static const double _openHalf = 0.05;
  static const double _openDepth = 0.018;
  static const double _openDepthTalk = 0.05;
  static const double _openRound = 1.5;
  static const Offset _ohAt = Offset(0, 0.018);
  static const double _ohW = 0.05;
  static const double _ohH = 0.03;
  static const double _ohHGrow = 0.035;

  // ── Sprout ─────────────────────────────────────────────────────────────
  static const Offset _sproutBase = Offset(0.5, 0.25);
  static const double _swayAngle = 0.28;

  // ── Sparkle ────────────────────────────────────────────────────────────
  static const Offset _sparkle = Offset(0.84, 0.2);
  static const double _sparkleR = 0.085;
  static const double _sparkleGrow = 0.35;
  static const double _sparkleSpin = 0.7;
  static const Offset _spark = Offset(0.93, 0.36);
  static const double _sparkR = 0.042;

  /// The small spark only shows once it is a few pixels wide (a sliver of
  /// a star under a thick rim is degenerate geometry for some GPUs).
  static const double _sparkFrom = 0.25;
  static const double _sparkleInk = 0.018;
  static const double _starPinch = 0.16;

  /// A four-point sparkle of [radius] pixels around the origin.
  static Path _star(double radius) {
    const tips = [Offset(1, 0), Offset(0, 1), Offset(-1, 0), Offset(0, -1)];
    final path = Path()..moveTo(0, -radius);
    var from = const Offset(0, -1);
    for (final to in tips) {
      final control = (from + to) * _starPinch * radius;
      path.quadraticBezierTo(
        control.dx,
        control.dy,
        to.dx * radius,
        to.dy * radius,
      );
      from = to;
    }
    return path..close();
  }

  static Paint _ink() => Paint()..color = AppColors.stickerOutline;

  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final u = side * _fit;
    final shapes = AssistantMascotGeometry.of(u);
    final feet = _feet * u;
    canvas
      ..save()
      ..translate(
        (size.width - side) / 2 + _fitShift.dx * side,
        (size.height - side) / 2 + _fitShift.dy * side,
      )
      // Squash & stretch from the feet.
      ..translate(feet.dx, feet.dy)
      ..scale(1 + _squashX * pose.squash, 1 - _squashY * pose.squash)
      ..translate(-feet.dx, -feet.dy);

    if (outlined) canvas.drawPath(shapes.body, shapes.rim);
    _paintSprout(canvas, shapes, u);
    canvas.drawPath(shapes.body, shapes.bodyFill);
    _paintGloss(canvas, u);
    _paintFace(canvas, u);
    _paintSparkles(canvas, u);
    canvas.restore();
  }

  void _paintSprout(Canvas canvas, AssistantMascotGeometry shapes, double u) {
    final base = _sproutBase * u;
    canvas
      ..save()
      ..translate(base.dx, base.dy)
      ..rotate(pose.sway * _swayAngle)
      ..translate(-base.dx, -base.dy);
    if (outlined) {
      canvas
        ..drawPath(shapes.stem, shapes.rim)
        ..drawPath(shapes.leftLeaf, shapes.rim)
        ..drawPath(shapes.rightLeaf, shapes.rim);
    }
    canvas
      ..drawPath(shapes.stem, shapes.stemPaint)
      ..drawPath(shapes.leftLeaf, shapes.leafFill)
      ..drawPath(shapes.rightLeaf, shapes.leafFill)
      ..drawPath(shapes.leftVein, shapes.veinPaint)
      ..restore();
  }

  void _paintGloss(Canvas canvas, double u) {
    final at = _gloss * u;
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(_glossTilt)
      ..drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: _glossW * u,
          height: _glossH * u,
        ),
        Paint()..color = AppColors.white.withValues(alpha: _glossAlpha),
      )
      ..restore();
  }

  void _paintFace(Canvas canvas, double u) {
    final face = Offset(pose.look.dx * _lookX, pose.look.dy * _lookY);
    final cheek = Paint()
      ..color = AppColors.magenta[_blushShade].withValues(
        alpha: math.min(1, _cheekAlpha + _cheekHappyAlpha * pose.happy),
      );
    for (final x in const [_cheekX, 1 - _cheekX]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: (Offset(x, _cheekY) + face * _cheekFollow) * u,
          width: _cheekW * u,
          height: _cheekH * u,
        ),
        cheek,
      );
    }

    // Laughing: the eyes close first, then curve into `^ ^`.
    final shut = math.min(1.0, pose.happy * 2);
    final laugh = math.max(0.0, pose.happy * 2 - 1);
    final grow = 1 + _surpriseGrow * pose.surprise;
    for (final side in const [-1.0, 1.0]) {
      final center = (Offset(0.5 + side * _eyeX, _eyeY) + face) * u;
      final blink = side > 0 ? math.max(pose.blink, pose.wink) : pose.blink;
      if (laugh == 0) {
        final height = math.max(
          _eyeMinH,
          _eyeH * grow * (1 - blink) * (1 - shut),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: _eyeW * grow * u,
            height: height * u,
          ),
          _ink(),
        );
        if (blink < 0.5 && shut < 0.5) {
          canvas.drawCircle(
            center + _glintAt * grow * u,
            _glint * grow * u,
            Paint()..color = AppColors.white,
          );
        }
      } else {
        final arc = Path()
          ..moveTo(center.dx - _arcHalf * u, center.dy + _arcDrop * u)
          ..quadraticBezierTo(
            center.dx,
            center.dy - _arcRise * laugh * u,
            center.dx + _arcHalf * u,
            center.dy + _arcDrop * u,
          );
        canvas.drawPath(arc, _line(AppColors.stickerOutline, _stroke * u));
      }
    }
    _paintMouth(canvas, (Offset(0.5, _mouthY) + face) * u, u);
  }

  void _paintMouth(Canvas canvas, Offset at, double u) {
    if (pose.surprise >= _openFrom && pose.surprise > pose.talk) {
      canvas.drawOval(
        Rect.fromCenter(
          center: at + _ohAt * u,
          width: _ohW * u,
          height: (_ohH + _ohHGrow * pose.surprise) * u,
        ),
        _ink(),
      );
      return;
    }
    if (pose.talk < _openFrom) {
      final half = (_smileHalf + _smileWiden * pose.happy) * u;
      final smile = Path()
        ..moveTo(at.dx - half, at.dy)
        ..quadraticBezierTo(
          at.dx,
          at.dy + (_smileDip + _smileDipHappy * pose.happy) * u,
          at.dx + half,
          at.dy,
        );
      canvas.drawPath(smile, _line(AppColors.stickerOutline, _stroke * u));
      return;
    }
    final half = _openHalf * u;
    final depth = (_openDepth + _openDepthTalk * pose.talk) * u;
    final mouth = Path()
      ..moveTo(at.dx - half, at.dy)
      ..quadraticBezierTo(
        at.dx,
        at.dy - _openDepth * u / 2,
        at.dx + half,
        at.dy,
      )
      ..cubicTo(
        at.dx + half,
        at.dy + depth * _openRound,
        at.dx - half,
        at.dy + depth * _openRound,
        at.dx - half,
        at.dy,
      )
      ..close();
    canvas.drawPath(mouth, _ink());
  }

  void _paintSparkles(Canvas canvas, double u) {
    final t = pose.twinkle;
    _paintStar(
      canvas,
      _sparkle * u,
      _sparkleR * (1 + _sparkleGrow * t) * u,
      _sparkleSpin * t,
      u,
    );
    if (t >= _sparkFrom) {
      _paintStar(canvas, _spark * u, _sparkR * t * u, -_sparkleSpin * t, u);
    }
  }

  void _paintStar(
    Canvas canvas,
    Offset at,
    double radius,
    double spin,
    double u,
  ) {
    final star = _star(radius);
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(spin);
    // No stroke fatter than the star it outlines.
    if (outlined) {
      canvas.drawPath(
        star,
        _line(
          AppColors.white,
          math.min(AssistantMascotGeometry.rimWidth * u, radius),
        ),
      );
    }
    canvas
      ..drawPath(star, Paint()..color = AppColors.accent4)
      ..drawPath(
        star,
        _line(AppColors.accent3, math.min(_sparkleInk * u, radius / 2)),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(AssistantMascotPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.outlined != outlined;
}
