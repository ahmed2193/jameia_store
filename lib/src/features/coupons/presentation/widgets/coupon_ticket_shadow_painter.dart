import 'package:flutter/widgets.dart';

/// Soft drop shadow under a coupon ticket: the card's rounded box, moved down
/// by [offsetY] and blurred by [blurSigma], in [color]. Painted behind the
/// ticket.
///
/// A blurred rounded rect, not the notched outline: an RRect takes the
/// renderer's analytic blur, while an arbitrary path is blurred offscreen on
/// every frame. Under a 6–12 sigma blur the small seam notches do not show in
/// the shadow anyway; the clip and the outline stroke keep the exact shape.
class CouponTicketShadowPainter extends CustomPainter {
  const CouponTicketShadowPainter({
    required this.cornerRadius,
    required this.color,
    required this.blurSigma,
    required this.offsetY,
  });

  final double cornerRadius;
  final Color color;
  final double blurSigma;
  final double offsetY;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).shift(Offset(0, offsetY)),
        Radius.circular(cornerRadius),
      ),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
    );
  }

  @override
  bool shouldRepaint(CouponTicketShadowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.blurSigma != blurSigma ||
      oldDelegate.offsetY != offsetY ||
      oldDelegate.cornerRadius != cornerRadius;
}
