import 'package:flutter/widgets.dart';

/// Another size of the same image, already complete in RAM, painted in the
/// tile's box until the right size decodes (the load policy's `variant`
/// decision: a fidelity floor instead of a shimmer). [image] must be the
/// exact provider the package builds for that variant (`imageRamProvider`),
/// so it resolves synchronously: no blank frame, no shimmer, no fade.
/// [still] (the tile's `HeroImageStillBox`) covers a frame that does not
/// come synchronously — a live-only entry under a scroll-aware provider can
/// wait a frame — so the box is never transparent.
class HeroImageVariantPlaceholder extends StatelessWidget {
  const HeroImageVariantPlaceholder({
    super.key,
    required this.image,
    required this.still,
    this.fit,
    this.width,
    this.height,
  });

  final ImageProvider<Object> image;
  final Widget still;
  final BoxFit? fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Image(
    image: image,
    fit: fit,
    width: width,
    height: height,
    gaplessPlayback: true,
    filterQuality: FilterQuality.low,
    excludeFromSemantics: true,
    frameBuilder: (BuildContext context, Widget child, int? frame, bool _) =>
        frame == null
        ? SizedBox(width: width, height: height, child: still)
        : child,
  );
}
