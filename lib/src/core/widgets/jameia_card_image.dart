import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import 'jameia_image.dart';

/// Rounded-card image used in product/shop cards.
class JameiaCardImage extends StatelessWidget {
  const JameiaCardImage({
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
      JameiaImage(url: url, width: width, height: height, radius: radius);
}
