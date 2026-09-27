import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/hero_image.dart';
import 'pdp_photo_flight.dart';

/// One product photo, contained in the biggest square its box allows, that
/// flies between the page's gallery and the full-screen viewer: a [Hero]
/// tagged [tagFor]. Both ends are squares, so the flight only scales it
/// ([PdpPhotoFlight]). No flight under reduced motion.
class PdpPhoto extends StatelessWidget {
  const PdpPhoto({
    super.key,
    required this.url,
    required this.index,
    required this.productSlug,
  });

  final String url;

  /// Its place among the product's photos (part of the flight's tag).
  final int index;

  /// The product it belongs to (part of the flight's tag), so a product page
  /// pushed over another one that shows the same photo never flies it.
  final String productSlug;

  /// The flight tag of photo [index] at [url] of [productSlug].
  static String tagFor(String productSlug, String url, int index) =>
      'pdp-photo:$productSlug:$index:$url';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: HeroMode(
          enabled: !MotionGuard.reduced(context),
          child: Hero(
            tag: tagFor(productSlug, url, index),
            flightShuttleBuilder: (_, _, _, from, _) =>
                PdpPhotoFlight.leaving(from),
            child: HeroImage(url: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
