import 'package:equatable/equatable.dart';

/// Framework-free promo-tag entity — a styled promotional chip shown on a shop
/// card / meta strip. Owned by the shop feature (no reuse of the core `PromoTag`
/// DTO). [style] picks the visual treatment: `ribbon` | `coupon` | `pill`.
class PromoTagEntity extends Equatable {
  const PromoTagEntity({
    required this.text,
    this.bg = '#D90012',
    this.fg = '#FFFFFF',
    this.style = 'ribbon',
  });

  final String text;

  /// Hex background / foreground colour.
  final String bg;
  final String fg;

  /// ribbon | coupon | pill.
  final String style;

  @override
  List<Object?> get props => [text, bg, fg, style];
}
