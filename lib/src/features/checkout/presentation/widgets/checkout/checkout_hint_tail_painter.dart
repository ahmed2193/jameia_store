import 'package:flutter/rendering.dart';

/// The savings hint's tail: a solid triangle pointing down, its tip at the
/// bottom centre of the canvas (direction-neutral, so it is not mirrored).
class CheckoutHintTailPainter extends CustomPainter {
  const CheckoutHintTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final tail = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / _halves, size.height)
      ..close();
    canvas.drawPath(
      tail,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  static const int _halves = 2;

  @override
  bool shouldRepaint(CheckoutHintTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
