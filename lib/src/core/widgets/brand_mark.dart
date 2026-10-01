import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An official brand mark (`HeroAssets.brand*`: Google, Apple, Facebook,
/// Instagram, X; or `HeroAssets.flagKuwait`) in a [size] square (or a
/// [size] × [height] box for a mark that is not square, like the 2:1 flag),
/// drawn exactly as its owner ships it:
/// never tinted, recoloured or mirrored. A `.svg` mark is drawn with
/// [SvgPicture]; a raster mark (with its 2x / 3x variants) with [Image].
///
/// Decorative: the label beside it names the brand, so the mark stays out of
/// the semantics tree.
class BrandMark extends StatelessWidget {
  const BrandMark(this.asset, {super.key, required this.size, this.height});

  static const String _vectorExtension = '.svg';

  /// A `HeroAssets.brand*` path.
  final String asset;
  final double size;

  /// The box height; [size] (a square) when null.
  final double? height;

  /// Whether [asset] is a vector mark (drawn with [SvgPicture]).
  bool get isVector => asset.toLowerCase().endsWith(_vectorExtension);

  @override
  Widget build(BuildContext context) {
    if (isVector) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: height ?? size,
        excludeFromSemantics: true,
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: height ?? size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
