import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../responsive/app_size.dart';

/// One of the drawn `HeroAssets` colour SVGs (a plate, sticker, prop or
/// marker) at a fixed box — colours baked in, never tinted
/// (docs/motion/asset_manifest.md). Line icons are `HeroIcons` font glyphs
/// drawn with [Icon].
///
/// [size] (the width) falls back to the [IconTheme] size, then 24 dp;
/// [height] defaults to [size], for a drawing that is not square (the art
/// is fitted inside the box). [semanticLabel] (an i18n string) is read out
/// when the picture carries meaning on its own; without one the art is
/// decorative and left out of the semantics tree. [matchTextDirection]
/// mirrors a directional drawing under RTL.
///
/// Parsing is shared: flutter_svg keeps one compiled copy per asset
/// (`svg.cache`) and one decoded picture per asset on screen, so art
/// repeated down a list is parsed once.
class HeroSvgGlyph extends StatelessWidget {
  const HeroSvgGlyph.art(
    this.asset, {
    super.key,
    this.size,
    this.height,
    this.semanticLabel,
    this.matchTextDirection = false,
  });

  /// A `HeroAssets` path.
  final String asset;
  final double? size;
  final double? height;
  final String? semanticLabel;
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    final side = size ?? IconTheme.of(context).size ?? AppSize.s24;
    return SvgPicture.asset(
      asset,
      width: side,
      height: height ?? side,
      matchTextDirection: matchTextDirection,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
