import 'package:flutter/painting.dart';

/// The spent-coupon look, applied colour by colour: a luminance greyscale
/// lifted a quarter toward white, alpha unchanged.
///
/// A used or expired ticket passes every colour it paints through [of]
/// instead of sitting under a `ColorFiltered` (which would give each card its
/// own offscreen layer). The matrix is affine with rows that sum to one, so
/// fading each colour before painting gives the same pixels as filtering the
/// painted card.
abstract final class CouponFade {
  /// Row-major 4 × 5 colour matrix, in the `ColorFilter.matrix` layout: the
  /// fifth column is the offset in 0..255.
  static const List<double> matrix = <double>[
    0.16, 0.54, 0.05, 0, 64, //
    0.16, 0.54, 0.05, 0, 64, //
    0.16, 0.54, 0.05, 0, 64, //
    0, 0, 0, 1, 0, //
  ];

  static const double _offsetScale = 255;
  static const int _rowLength = 5;

  /// [color] faded (greyscale, lifted toward white).
  static Color apply(Color color) {
    double row(int i) {
      final at = i * _rowLength;
      final value =
          matrix[at] * color.r +
          matrix[at + 1] * color.g +
          matrix[at + 2] * color.b +
          matrix[at + 3] * color.a +
          matrix[at + 4] / _offsetScale;
      return value.clamp(0.0, 1.0);
    }

    return Color.from(
      alpha: row(3),
      red: row(0),
      green: row(1),
      blue: row(2),
      colorSpace: color.colorSpace,
    );
  }

  /// [color] faded when [faded], as is otherwise.
  static Color of(Color color, {required bool faded}) =>
      faded ? apply(color) : color;

  /// Every colour of [colors] faded when [faded], the list as is otherwise.
  static List<Color> all(List<Color> colors, {required bool faded}) =>
      faded ? colors.map(apply).toList(growable: false) : colors;
}
