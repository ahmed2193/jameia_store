import 'package:equatable/equatable.dart';

/// A styled promotional tag shown on a shop card / shop meta strip.
///
/// [style] picks the visual treatment: `ribbon` | `coupon` | `pill`. Colours
/// stay raw hex strings; presentation resolves them to `Color`s.
class PromoTagEntity extends Equatable {
  const PromoTagEntity({
    required this.text,
    this.bg = '#D90012',
    this.fg = '#FFFFFF',
    this.style = 'ribbon',
  });

  final String text;

  /// Background hex colour.
  final String bg;

  /// Foreground hex colour.
  final String fg;

  /// ribbon | coupon | pill.
  final String style;

  @override
  List<Object?> get props => [text, bg, fg, style];
}
