import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One confetti piece: where it flies and how it looks (normalized units,
/// resolved against the canvas size at paint time).
@immutable
class ConfettiPiece {
  const ConfettiPiece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.color,
    required this.isRound,
  });

  /// Launch direction in radians (−π/2 = straight up).
  final double angle;

  /// Launch speed as a fraction of the canvas height per unit of time.
  final double speed;
  final double spin;
  final Color color;
  final bool isRound;

  static const int _seed = 7;
  static const double _spread = math.pi * 0.9;
  static const double _minSpeed = 0.9;
  static const double _speedRange = 0.8;
  static const double _maxSpin = 12;
  static const double _centre = 0.5;

  /// [count] pieces fanned upwards from a fixed [seed] (the same recipe
  /// `ConfettiBurst` uses), cycling through [colors]; alternate pieces round.
  static List<ConfettiPiece> scatter({
    required List<Color> colors,
    required int count,
    int seed = _seed,
  }) {
    if (colors.isEmpty) return const <ConfettiPiece>[];
    final random = math.Random(seed);
    return List<ConfettiPiece>.generate(count, (i) {
      final angle = -math.pi / 2 + (random.nextDouble() - _centre) * _spread;
      return ConfettiPiece(
        angle: angle,
        speed: _minSpeed + random.nextDouble() * _speedRange,
        spin: (random.nextDouble() - _centre) * _maxSpin,
        color: colors[i % colors.length],
        isRound: i.isOdd,
      );
    }, growable: false);
  }
}

/// Paints [pieces] launched from [origin] (fractions of the size) at
/// [progress] 0→1: ballistic flight under gravity, a spin, and a fade over the
/// last third. Stateless: the widget owns the animation.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.origin,
  }) : super(repaint: progress);

  static const double _gravity = 1.6;
  static const double _pieceLength = 10;
  static const double _pieceWidth = 6;
  static const double _fadeFrom = 0.66;

  final List<ConfettiPiece> pieces;
  final Animation<double> progress;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final fade = t < _fadeFrom ? 1.0 : (1 - t) / (1 - _fadeFrom);
    final start = Offset(origin.dx * size.width, origin.dy * size.height);
    final paint = Paint();
    for (final piece in pieces) {
      final distance = piece.speed * size.height * t;
      final dx = math.cos(piece.angle) * distance;
      final dy =
          math.sin(piece.angle) * distance + _gravity * size.height * t * t / 2;
      paint.color = piece.color.withValues(alpha: piece.color.a * fade);
      canvas
        ..save()
        ..translate(start.dx + dx, start.dy + dy)
        ..rotate(piece.spin * t);
      if (piece.isRound) {
        canvas.drawCircle(Offset.zero, _pieceWidth / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: _pieceLength,
            height: _pieceWidth,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.origin != origin;
}
