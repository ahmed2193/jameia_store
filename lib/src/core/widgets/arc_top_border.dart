import 'package:flutter/widgets.dart';

import '../responsive/app_size.dart';

/// A panel whose top edge is a shallow arc — highest in the middle, [rise]
/// lower at both sides — with straight sides and bottom: the Glovo-style
/// sheet that rises over a map (the map picker's building-type panel). Pass
/// it as a sheet's `shape`; it paints no border of its own.
class ArcTopBorder extends ShapeBorder {
  const ArcTopBorder({this.rise = AppSize.s16});

  /// How much lower the ends of the top edge sit than its middle.
  final double rise;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  /// A quadratic curve from one top corner to the other whose control point
  /// sits [rise] above the top, so its middle touches the top exactly.
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..moveTo(rect.left, rect.top + rise)
    ..quadraticBezierTo(
      rect.center.dx,
      rect.top - rise,
      rect.right,
      rect.top + rise,
    )
    ..lineTo(rect.right, rect.bottom)
    ..lineTo(rect.left, rect.bottom)
    ..close();

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => ArcTopBorder(rise: rise * t);

  @override
  bool operator ==(Object other) => other is ArcTopBorder && other.rise == rise;

  @override
  int get hashCode => rise.hashCode;
}
