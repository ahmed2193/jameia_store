import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../responsive/app_size.dart';

/// One of the drawn `HeroAssets` SVGs at a fixed box — the vector partner of
/// [Icon] for the Hero glyph set (docs/motion/asset_manifest.md).
///
/// - [HeroSvgGlyph.mono]: a one-colour line icon drawn in `#111827`. It is
///   tinted with [color] (`srcIn`), or with the ambient [IconTheme] colour
///   when none is given, so it drops in where an `Icon` sat (a tab bar, a
///   list tile) and follows the selected / disabled colours of its host.
/// - [HeroSvgGlyph.art]: a colour plate, sticker or prop — colours baked in,
///   never tinted.
///
/// [size] falls back to the [IconTheme] size, then 24 dp. [semanticLabel]
/// (an i18n string) is read out when the picture carries meaning on its own;
/// without one the glyph is decorative and left out of the semantics tree.
/// [matchTextDirection] mirrors a directional drawing under RTL.
///
/// Parsing is shared: flutter_svg keeps one compiled copy per asset
/// (`svg.cache`) and one decoded picture per asset on screen, so a glyph
/// repeated down a list is parsed once.
class HeroSvgGlyph extends StatelessWidget {
  const HeroSvgGlyph.mono(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.matchTextDirection = false,
  }) : tinted = true;

  const HeroSvgGlyph.art(
    this.asset, {
    super.key,
    this.size,
    this.semanticLabel,
    this.matchTextDirection = false,
  }) : tinted = false,
       color = null;

  /// A `HeroAssets` path.
  final String asset;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final bool matchTextDirection;

  /// Whether the drawing is a mono icon painted in [color].
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? AppSize.s24;
    final tint = tinted ? color ?? theme.color : null;
    return SvgPicture.asset(
      asset,
      width: side,
      height: side,
      matchTextDirection: matchTextDirection,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
