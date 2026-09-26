import 'package:flutter/widgets.dart';

/// The tear line down a coupon ticket's seam: a column of small [color] holes
/// centred on the box's vertical midline, stopping [inset] short of the top
/// and bottom edges (where the notches are). Over the stub's colour they read
/// as a punched, scalloped edge.
class CouponPerforationPainter extends CustomPainter {
  const CouponPerforationPainter({
    required this.color,
    required this.inset,
    required this.holeRadius,
    required this.gap,
  });

  final Color color;
  final double inset;
  final double holeRadius;

  /// Space between two holes.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final x = size.width / 2;
    final span = size.height - inset * 2;
    final step = holeRadius * 2 + gap;
    if (span <= 0 || step <= 0) return;
    final count = (span / step).floor();
    // Centre the column so both ends sit the same distance from the notches.
    final first = inset + (span - (count - 1) * step) / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(Offset(x, first + i * step), holeRadius, paint);
    }
  }

  @override
  bool shouldRepaint(CouponPerforationPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.inset != inset ||
      oldDelegate.holeRadius != holeRadius ||
      oldDelegate.gap != gap;
}
