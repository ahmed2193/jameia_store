import 'package:flutter/rendering.dart';

/// A dashed hairline across the box, like the tear line of a paper receipt.
class InvoicePerforationPainter extends CustomPainter {
  const InvoicePerforationPainter({
    required this.color,
    required this.dash,
    required this.gap,
    required this.thickness,
  });

  final Color color;
  final double dash;
  final double gap;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(InvoicePerforationPainter oldDelegate) =>
      color != oldDelegate.color ||
      dash != oldDelegate.dash ||
      gap != oldDelegate.gap ||
      thickness != oldDelegate.thickness;
}
