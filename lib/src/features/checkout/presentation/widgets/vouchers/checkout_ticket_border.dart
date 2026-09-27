import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// The Hero voucher ticket: a card with [radius] corners and one
/// semicircle notch of [notchRadius] cut into each side edge at its
/// vertical centre, so the page background shows through (the ticket's
/// perforation). Symmetric, so it needs no mirroring in RTL.
///
/// The outline is built from arcs (no path boolean) and cached per size:
/// cards of one list share one path, and a card that keeps its size never
/// rebuilds it.
class CheckoutTicketBorder extends ShapeBorder {
  const CheckoutTicketBorder();

  static const double radius = AppRadius.media;
  static const double notchRadius = AppSize.s8;

  static const double _half = 0.5;

  /// A handful of card sizes per page; the cache never grows past this.
  static const int _cacheLimit = 16;
  static final Map<Size, Path> _paths = <Size, Path>{};

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = _pathFor(rect.size);
    return rect.topLeft == Offset.zero ? path : path.shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  static Path _pathFor(Size size) {
    final cached = _paths[size];
    if (cached != null) return cached;
    if (_paths.length >= _cacheLimit) _paths.clear();
    return _paths[size] = _outline(size);
  }

  static Path _outline(Size size) {
    final w = size.width;
    final h = size.height;
    final r = math.min(radius, math.min(w, h) * _half);
    final n = math.max<double>(0, math.min(notchRadius, h * _half - r));
    final mid = h * _half;
    final corner = Radius.circular(r);
    final notch = Radius.circular(n);
    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: corner)
      ..lineTo(w, mid - n)
      // Cut inwards: the arc runs through the card, not outside it.
      ..arcToPoint(Offset(w, mid + n), radius: notch, clockwise: false)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: corner)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: corner)
      ..lineTo(0, mid + n)
      ..arcToPoint(Offset(0, mid - n), radius: notch, clockwise: false)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: corner)
      ..close();
  }
}
