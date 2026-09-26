import 'package:flutter/widgets.dart';

import '../../../../core/responsive/app_size.dart';

/// Wavy top and bottom edges of the paywall's full-bleed bands (the hero and
/// the free-delivery band). Each edge dips at most 2 × [amplitude] into the
/// band, so the content keeps at least that much padding at both ends.
class ProWaveClipper extends CustomClipper<Path> {
  const ProWaveClipper({
    this.amplitude = AppSize.s8,
    this.waves = _defaultWaves,
  });

  static const int _defaultWaves = 2;

  /// A quadratic segment peaks half-way to its control point.
  static const double _controlReach = 2;

  final double amplitude;

  /// Crest + trough pairs along each edge.
  final int waves;

  @override
  Path getClip(Size size) {
    final segments = waves * 2;
    final step = size.width / segments;
    final reach = amplitude * _controlReach;
    final top = amplitude;
    final bottom = size.height - amplitude;
    final path = Path()..moveTo(0, top);
    for (var i = 0; i < segments; i++) {
      final control = i.isEven ? top - reach : top + reach;
      path.quadraticBezierTo(step * (i + 0.5), control, step * (i + 1), top);
    }
    path.lineTo(size.width, bottom);
    for (var i = segments; i > 0; i--) {
      final control = i.isEven ? bottom + reach : bottom - reach;
      path.quadraticBezierTo(step * (i - 0.5), control, step * (i - 1), bottom);
    }
    return path..close();
  }

  @override
  bool shouldReclip(ProWaveClipper oldClipper) =>
      oldClipper.amplitude != amplitude || oldClipper.waves != waves;
}
