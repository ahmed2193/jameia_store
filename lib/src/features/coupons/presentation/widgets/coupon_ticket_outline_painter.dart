import 'package:flutter/widgets.dart';

import 'coupon_ticket_clipper.dart';

/// Strokes a coupon ticket's outline (notches included) in [color] at
/// [strokeWidth]: a hairline at rest, the accent ring on a picked coupon.
class CouponTicketOutlinePainter extends CustomPainter {
  const CouponTicketOutlinePainter({
    required this.stubWidth,
    required this.notchRadius,
    required this.cornerRadius,
    required this.rtl,
    required this.color,
    required this.strokeWidth,
  });

  final double stubWidth;
  final double notchRadius;
  final double cornerRadius;
  final bool rtl;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawPath(
      CouponTicketClipper.pathFor(
        size,
        stubWidth: stubWidth,
        notchRadius: notchRadius,
        cornerRadius: cornerRadius,
        rtl: rtl,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CouponTicketOutlinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.stubWidth != stubWidth ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.rtl != rtl;
}
