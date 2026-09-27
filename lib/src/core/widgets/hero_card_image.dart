import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import 'hero_image.dart';

/// Rounded-card image used in product/shop cards.
class HeroCardImage extends StatelessWidget {
  const HeroCardImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppRadius.card,
  });

  final String url;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      HeroImage(url: url, width: width, height: height, radius: radius);
}
