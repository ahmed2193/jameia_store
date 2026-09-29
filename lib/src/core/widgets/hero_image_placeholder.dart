import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_assets.dart';
import '../responsive/app_size.dart';

/// What an image box shows before its photo lands (and for a product with
/// no photo): the soft grey fill with the Hero bag outline
/// ([HeroAssets.imagePlaceholder]) in its middle — sized to the box (about
/// 40 % of its short side, 16–48 dp), left out of boxes too small to hold
/// it. Decorative: never announced.
class HeroImagePlaceholder extends StatelessWidget {
  const HeroImagePlaceholder({super.key});

  static const double _share = 0.4;
  static const double _minGlyph = AppSize.s16;
  static const double _maxGlyph = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.smallBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortest = constraints.biggest.shortestSide;
          final glyph = shortest.isFinite ? shortest * _share : _maxGlyph;
          if (glyph < _minGlyph) return const SizedBox.shrink();
          final side = glyph > _maxGlyph ? _maxGlyph : glyph;
          return Center(
            child: SvgPicture.asset(
              HeroAssets.imagePlaceholder,
              width: side,
              height: side,
              excludeFromSemantics: true,
            ),
          );
        },
      ),
    );
  }
}
