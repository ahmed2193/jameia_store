import 'package:flutter/material.dart';

import '../design/jameia_assets.dart';
import '../motion/motion.dart';
import '../../config/theme/app_colors.dart';
import 'branded_dot_loader.dart';

/// Branded loading indicator. Replaces bare [CircularProgressIndicator] so every
/// loader in the app shares Jameia's look.
///
/// * Default ([BrandedLoader.new]) shows the real Jameia brand loading GIF
///   ([JameiaAssets.brandLoadingGif], ~2.2 MB) — use for full-screen / block
///   loads only.
/// * [BrandedLoader.inline] paints a lightweight three-dot pulse (no GIF decode)
///   for buttons and tight inline spots. Loop length = [AppMotion.lottieDotLoader].
///
/// Reduced-motion → a static dot row (inline) / static first frame (GIF host
/// pauses naturally), so nothing animates.
class BrandedLoader extends StatelessWidget {
  const BrandedLoader({super.key, this.size = 48})
    : _inline = false,
      color = null;

  const BrandedLoader.inline({super.key, this.size = 22, this.color})
    : _inline = true;

  final double size;
  final bool _inline;

  /// Inline dot color (defaults to the brand foreground / on-button color).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (_inline) {
      return BrandedDotLoader(
        size: size,
        color: color ?? AppColors.brandForeground,
      );
    }
    return Center(
      child: Image.asset(
        JameiaAssets.brandLoadingGif,
        width: size,
        height: size,
        gaplessPlayback: true,
        // If the GIF asset is ever missing, fall back to the dot loader rather
        // than throwing a broken-image box on a loading screen.
        errorBuilder: (_, _, _) =>
            BrandedDotLoader(size: size * 0.5, color: AppColors.primary),
      ),
    );
  }
}
