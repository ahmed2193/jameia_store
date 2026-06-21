import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Sized, cached network image with skeleton placeholder + graceful error tile.
/// The single image entry point for feature code (never raw `Image.network`).
class KeetaImage extends StatelessWidget {
  const KeetaImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(color: AppColors.smallBackground);
    final image = url.isEmpty
        ? Container(
            color: AppColors.smallBackground,
            width: width,
            height: height,
            child: const Icon(Icons.image_outlined,
                color: AppColors.disabledText, size: 28),
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => Container(
              color: AppColors.smallBackground,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.disabledText, size: 28),
            ),
          );

    if (radius <= 0) return image;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }

  /// Circular avatar variant.
  static Widget circle({required String url, required double size}) =>
      ClipOval(
        child: KeetaImage(url: url, width: size, height: size),
      );
}

/// Rounded-card image used in product/shop cards.
class KeetaCardImage extends StatelessWidget {
  const KeetaCardImage({
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
      KeetaImage(url: url, width: width, height: height, radius: radius);
}
