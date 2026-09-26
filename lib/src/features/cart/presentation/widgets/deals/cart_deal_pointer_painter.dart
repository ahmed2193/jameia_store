import 'package:flutter/rendering.dart';

/// The small triangle under the selected deal card, pointing up at it from
/// the product grid below (drawn in the grid's colour).
class CartDealPointerPainter extends CustomPainter {
  const CartDealPointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CartDealPointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
