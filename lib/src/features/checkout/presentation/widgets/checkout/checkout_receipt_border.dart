import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// The receipt card of "Order totals": a flat fill whose top and bottom
/// edges are bitten by a row of semicircles (the page shows through them),
/// like a till roll torn at both ends.
///
/// Geometry (Keeta, measured): bites of [biteRadius] whose centres sit
/// [biteOffset] outside the edge, one every [period], the row centred on
/// the card; the bottom row mirrors the top one in the same columns. It is
/// symmetric, so it needs no RTL handling.
///
/// Only the two bitten strips are paths, built from arcs (no path boolean
/// operations) and cached per **width**: the card grows and shrinks while
/// an optional row opens, and that only moves the bottom strip and
/// stretches the plain rectangle between them — no path is rebuilt. The
/// fill is opaque, so the strips and the rectangle may overlap.
class CheckoutReceiptBorder extends CustomPainter {
  const CheckoutReceiptBorder({required this.color});

  static const double biteRadius = AppSize.s12;
  static const double period = AppSpacing.s32;
  static const double biteOffset = AppSize.s2;

  /// How far a bite reaches into the card.
  static const double biteDepth = biteRadius - biteOffset;

  /// Height of each cached strip: the bites plus a little solid fill.
  static const double _strip = biteRadius;

  static const Radius _arc = Radius.circular(biteRadius);

  /// The strips of the last width painted (one receipt on screen at once).
  static _ReceiptStrips? _cache;

  /// How many times the strips were built; tests pin the per-width cache.
  @visibleForTesting
  static int debugPathBuilds = 0;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final strips = _stripsFor(size.width);
    final paint = Paint()..color = color;
    final middleBottom = math.max(biteDepth, size.height - biteDepth);
    canvas
      ..drawPath(strips.top, paint)
      ..drawRect(Rect.fromLTRB(0, biteDepth, size.width, middleBottom), paint)
      ..save()
      ..translate(0, math.max(0, size.height - _strip))
      ..drawPath(strips.bottom, paint)
      ..restore();
  }

  static _ReceiptStrips _stripsFor(double width) {
    final cached = _cache;
    if (cached != null && cached.width == width) return cached;
    debugPathBuilds++;
    final strips = _ReceiptStrips(
      width: width,
      top: _topStrip(width),
      bottom: _bottomStrip(width),
    );
    _cache = strips;
    return strips;
  }

  /// The x of every bite centre: as many as fit, the group centred.
  static List<double> _centres(double width) {
    final count = (width / period).floor();
    final first = (width - count * period) / 2 + period / 2;
    return <double>[for (var i = 0; i < count; i++) first + i * period];
  }

  /// Half the chord a bite cuts on the edge.
  static double get _halfChord =>
      math.sqrt(biteRadius * biteRadius - biteOffset * biteOffset);

  /// `y = 0` is the card's top edge; the bites dip down into the strip.
  static Path _topStrip(double width) {
    final half = _halfChord;
    final path = Path()..moveTo(0, 0);
    for (final x in _centres(width)) {
      path
        ..lineTo(x - half, 0)
        // The centre sits above the edge, so the bite (the part of the
        // circle below the chord) is the minor arc, drawn left to right
        // through the bottom: counter-clockwise on screen.
        ..arcToPoint(Offset(x + half, 0), radius: _arc, clockwise: false);
    }
    return path
      ..lineTo(width, 0)
      ..lineTo(width, _strip)
      ..lineTo(0, _strip)
      ..close();
  }

  /// `y = _strip` is the card's bottom edge; the bites rise into the strip.
  static Path _bottomStrip(double width) {
    final half = _halfChord;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, _strip);
    for (final x in _centres(width).reversed) {
      path
        ..lineTo(x + half, _strip)
        // Mirrored: the minor arc above the chord, right to left.
        ..arcToPoint(Offset(x - half, _strip), radius: _arc, clockwise: false);
    }
    return path
      ..lineTo(0, _strip)
      ..close();
  }

  @override
  bool shouldRepaint(CheckoutReceiptBorder oldDelegate) =>
      oldDelegate.color != color;
}

/// The two bitten strips built for one card width.
class _ReceiptStrips {
  const _ReceiptStrips({
    required this.width,
    required this.top,
    required this.bottom,
  });

  final double width;
  final Path top;
  final Path bottom;
}
