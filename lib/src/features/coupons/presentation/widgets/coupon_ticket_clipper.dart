import 'package:flutter/widgets.dart';

/// Outline of a coupon ticket: a rounded card with two semicircle notches
/// bitten out of its top and bottom edges on the perforation seam, [stubWidth]
/// from the start edge (from the right under RTL).
class CouponTicketClipper extends CustomClipper<Path> {
  const CouponTicketClipper({
    required this.stubWidth,
    required this.notchRadius,
    required this.cornerRadius,
    required this.rtl,
  });

  final double stubWidth;
  final double notchRadius;
  final double cornerRadius;
  final bool rtl;

  /// How many outlines [pathFor] keeps (the least recently used goes first).
  /// A list of tickets shares one or two sizes, so this is plenty.
  static const int cacheCapacity = 16;

  /// Recently built outlines by their inputs. A cached path is only read
  /// (clipped to, stroked, hit-tested), never mutated, so sharing it is safe.
  static final Map<(Size, double, double, double, bool), Path> _cache = {};

  /// The ticket outline for a box of [size]; shared with the outline painter
  /// so the stroke follows the clip exactly. The boolean `Path.combine` runs
  /// once per distinct input: later calls (every paint of every ticket of
  /// that size) return the same [Path].
  static Path pathFor(
    Size size, {
    required double stubWidth,
    required double notchRadius,
    required double cornerRadius,
    required bool rtl,
  }) {
    final key = (size, stubWidth, notchRadius, cornerRadius, rtl);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // Most recently used goes last.
      return cached;
    }
    final path = _build(
      size,
      stubWidth: stubWidth,
      notchRadius: notchRadius,
      cornerRadius: cornerRadius,
      rtl: rtl,
    );
    if (_cache.length >= cacheCapacity) _cache.remove(_cache.keys.first);
    _cache[key] = path;
    return path;
  }

  static Path _build(
    Size size, {
    required double stubWidth,
    required double notchRadius,
    required double cornerRadius,
    required bool rtl,
  }) {
    final seam = rtl ? size.width - stubWidth : stubWidth;
    final card = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(cornerRadius),
        ),
      );
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(seam, 0), radius: notchRadius))
      ..addOval(
        Rect.fromCircle(center: Offset(seam, size.height), radius: notchRadius),
      );
    return Path.combine(PathOperation.difference, card, notches);
  }

  @override
  Path getClip(Size size) => pathFor(
    size,
    stubWidth: stubWidth,
    notchRadius: notchRadius,
    cornerRadius: cornerRadius,
    rtl: rtl,
  );

  @override
  bool shouldReclip(CouponTicketClipper oldClipper) =>
      oldClipper.stubWidth != stubWidth ||
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.rtl != rtl;
}
