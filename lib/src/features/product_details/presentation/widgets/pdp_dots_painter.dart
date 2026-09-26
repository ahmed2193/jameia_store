import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The dots inside [PdpDotsPill]: [count] equal dots in a row, the page the
/// [controller] shows lit, the light easing from one dot to the next while
/// the finger drags. Laid out from the reading start, like the pages.
/// Repaints with the pager, so nothing around it rebuilds.
class PdpDotsPainter extends CustomPainter {
  PdpDotsPainter({
    required this.controller,
    required this.count,
    required this.dot,
    required this.gap,
    required this.lit,
    required this.resting,
    required this.textDirection,
  }) : super(repaint: controller);

  final PageController controller;
  final int count;

  /// Diameter of one dot, and the room between two.
  final double dot;
  final double gap;
  final Color lit;
  final Color resting;
  final ui.TextDirection textDirection;

  /// How wide [count] dots are.
  static double widthOf(
    int count, {
    required double dot,
    required double gap,
  }) => count <= 0 ? 0 : count * dot + (count - 1) * gap;

  /// The page shown, fractional while it moves; the first page until the
  /// pager is laid out.
  double get _page {
    final fallback = controller.initialPage.toDouble();
    if (!controller.hasClients) return fallback;
    return controller.page ?? fallback;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final page = _page;
    final radius = dot / 2;
    final ltr = textDirection == ui.TextDirection.ltr;
    final paint = Paint()..isAntiAlias = true;
    for (var index = 0; index < count; index++) {
      final light = (1 - (page - index).abs()).clamp(0.0, 1.0);
      paint.color = Color.lerp(resting, lit, light)!;
      final slot = ltr ? index : count - 1 - index;
      canvas.drawCircle(
        Offset(radius + slot * (dot + gap), size.height / 2),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PdpDotsPainter oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.count != count ||
      oldDelegate.dot != dot ||
      oldDelegate.gap != gap ||
      oldDelegate.lit != lit ||
      oldDelegate.resting != resting ||
      oldDelegate.textDirection != textDirection;
}
