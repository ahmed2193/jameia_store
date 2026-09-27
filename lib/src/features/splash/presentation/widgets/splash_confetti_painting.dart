import 'dart:math' as math;
import 'dart:ui';

import 'splash_assembly.dart';
import 'splash_frame.dart';
import 'splash_palette.dart';

typedef _Piece = ({
  double angle,
  double speed,
  double spin,
  int shape,
  int color,
  double size,
});

/// The small celebration once the bag has delivered the whole name: dots,
/// chips and leaves in the brand's accent colours pop up out of the name, arc
/// down under gravity, spin and fade. Deterministic (fixed seed), so every
/// launch — and every test — looks the same.
abstract final class SplashConfettiPainting {
  static const int pieceCount = 18;
  static const int _seed = 7;

  /// Launch speed range (dp/s), spread around straight up (radians) and
  /// gravity (dp/s²).
  static const double minSpeed = 200;
  static const double maxSpeed = 420;
  static const double spread = 2.2;
  static const double gravity = 900;

  /// Piece size range (dp) and the share of the run after which they fade.
  static const double minSize = 4;
  static const double maxSize = 8;
  static const double fadeFrom = 0.55;
  static const double maxSpin = 9;

  /// Chip and leaf proportions.
  static const double chipHeight = 0.55;
  static const double leafWidth = 0.55;
  static const double leafLength = 1.4;

  static final List<_Piece> _pieces = _scatter();

  static List<_Piece> _scatter() {
    final random = math.Random(_seed);
    double between(double a, double b) => a + random.nextDouble() * (b - a);
    return [
      for (var i = 0; i < pieceCount; i++)
        (
          angle: between(-spread / 2, spread / 2),
          speed: between(minSpeed, maxSpeed),
          spin: between(-maxSpin, maxSpin),
          shape: i % 3,
          color: i,
          size: between(minSize, maxSize),
        ),
    ];
  }

  static void paint(Canvas canvas, SplashFrame frame, SplashPalette palette) {
    final origin = frame.confettiOrigin;
    final run = frame.confetti;
    if (origin == null || run <= 0 || run >= 1) return;
    final seconds = run * SplashAssembly.confettiLength / 1000;
    final alpha = run < fadeFrom ? 1.0 : (1 - run) / (1 - fadeFrom);
    for (final piece in _pieces) {
      final position = origin.translate(
        math.sin(piece.angle) * piece.speed * seconds,
        -math.cos(piece.angle) * piece.speed * seconds +
            gravity * seconds * seconds / 2,
      );
      final color = palette.confetti[piece.color % palette.confetti.length];
      final paint = Paint()..color = color.withValues(alpha: color.a * alpha);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(piece.spin * seconds);
      final s = piece.size;
      switch (piece.shape) {
        case 0:
          canvas.drawCircle(Offset.zero, s / 2, paint);
        case 1:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: s,
              height: s * chipHeight,
            ),
            paint,
          );
        default:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * leafWidth,
              height: s * leafLength,
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }
}
