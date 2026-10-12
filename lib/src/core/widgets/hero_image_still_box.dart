import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import 'hero_image_shape.dart';

/// The first look of an image that is still loading: a plain tile in the
/// skeleton grey ([color], the shimmer's base), the image's own size and
/// shape, no glyph — painted once, no ticker, no animation. A disk hit shows
/// only this; a network load turns it into `HeroImageShimmer` after the
/// delay. (A slot with NO photo is `HeroImagePlaceholder`, not this.)
class HeroImageStillBox extends StatelessWidget {
  const HeroImageStillBox({super.key, this.shape = const HeroImageShape()});

  /// The tile colour: the skeleton family's base (`Skeletonized`).
  static const Color color = AppColors.divider;

  static const BoxDecoration _round = BoxDecoration(
    color: color,
    shape: BoxShape.circle,
  );

  final HeroImageShape shape;

  @override
  Widget build(BuildContext context) {
    final BorderRadius? corners = shape.borderRadius;
    final Widget tile = shape.circular
        ? const DecoratedBox(decoration: _round)
        : corners != null
        ? DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: corners),
          )
        : const ColoredBox(color: color);
    return SizedBox(width: shape.width, height: shape.height, child: tile);
  }
}
