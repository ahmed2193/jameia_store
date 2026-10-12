import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// The box an image tile fills and its corners: what every loading look of
/// `HeroImage` (the still box, the shimmer) paints, so swapping one for
/// another, or for the photo, never moves or reshapes the tile.
@immutable
class HeroImageShape {
  const HeroImageShape({
    this.width,
    this.height,
    this.radius = 0,
    this.circular = false,
  });

  /// The tile's explicit logical size; `null` fills the parent's constraints.
  final double? width;
  final double? height;

  /// Corner radius (ignored when [circular]).
  final double radius;

  /// A round tile (`HeroImage.circle`, `isCircular`).
  final bool circular;

  /// The rounded corners, or `null` for a square-cornered or round tile.
  BorderRadius? get borderRadius =>
      !circular && radius > 0 ? BorderRadius.circular(radius) : null;

  @override
  bool operator ==(Object other) =>
      other is HeroImageShape &&
      other.width == width &&
      other.height == height &&
      other.radius == radius &&
      other.circular == circular;

  @override
  int get hashCode => Object.hash(width, height, radius, circular);
}
