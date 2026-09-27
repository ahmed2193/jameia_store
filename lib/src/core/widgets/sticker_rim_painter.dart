import 'package:flutter/widgets.dart';

/// The dark rim of a `StickerText`, painted behind its letters: the same
/// text laid out the way the `Text` above it is (same style, scaler,
/// direction, alignment, lines and ellipsis, over the same width), stroked.
/// Painting it keeps the label a single `Text` for finders and readers.
class StickerRimPainter extends CustomPainter {
  StickerRimPainter({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.textScaler,
    required this.textAlign,
    required this.maxLines,
    required this.rim,
    required this.outline,
  });

  static const String _ellipsis = '…';

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final TextAlign textAlign;
  final int maxLines;
  final double rim;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rim
      ..strokeJoin = StrokeJoin.round
      ..color = outline;
    // copyWith drops the fill colour once a foreground paint is given.
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(foreground: stroke),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
      textAlign: textAlign,
      maxLines: maxLines,
      ellipsis: _ellipsis,
    )..layout(minWidth: size.width, maxWidth: size.width);
    painter.paint(canvas, Offset.zero);
    painter.dispose();
  }

  @override
  bool shouldRepaint(StickerRimPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.textAlign != textAlign ||
      oldDelegate.maxLines != maxLines ||
      oldDelegate.rim != rim ||
      oldDelegate.outline != outline;
}
