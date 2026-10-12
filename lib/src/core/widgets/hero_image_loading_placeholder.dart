import 'package:flutter/widgets.dart';

import 'hero_image_delayed_shimmer.dart';
import 'hero_image_placeholder_plan.dart';
import 'hero_image_shape.dart';
import 'hero_image_shimmer.dart';
import 'hero_image_still_box.dart';
import 'hero_image_variant_placeholder.dart';

/// What an image tile shows while it loads, by its [plan]
/// (`HeroRetryingImage` takes it from the load decision): the still box, the
/// still box turning into the shimmer, the shimmer, or a cached other size —
/// each in the tile's own box and [shape], so nothing moves when the photo
/// replaces it.
class HeroImageLoadingPlaceholder extends StatelessWidget {
  const HeroImageLoadingPlaceholder({
    super.key,
    required this.plan,
    required this.shape,
    this.fit,
    this.variantWidth,
    this.variantHeight,
  });

  final HeroImagePlaceholderPlan plan;
  final HeroImageShape shape;

  /// The cached variant's fit and box: sized like the final image, so the
  /// swap moves nothing.
  final BoxFit? fit;
  final double? variantWidth;
  final double? variantHeight;

  @override
  Widget build(BuildContext context) {
    final Widget still = HeroImageStillBox(shape: shape);
    final ImageProvider<Object>? cached = plan.image;
    return switch (plan.look) {
      HeroImageLoadingLook.still => still,
      HeroImageLoadingLook.quiet => HeroImageDelayedShimmer(
        delay: plan.delay,
        anchor: plan.anchor,
        still: still,
        shimmer: (_) => HeroImageShimmer(shape: shape),
      ),
      HeroImageLoadingLook.variant when cached != null =>
        HeroImageVariantPlaceholder(
          image: cached,
          still: still,
          fit: fit,
          width: variantWidth,
          height: variantHeight,
        ),
      HeroImageLoadingLook.shimmer || HeroImageLoadingLook.variant =>
        HeroImageShimmer(shape: shape, animate: plan.animate),
    };
  }
}
