import 'package:flutter/material.dart';

import '../design/jameia_assets.dart';
import '../motion/motion.dart';
import '../../config/theme/app_colors.dart';
import 'brand_moment_kind.dart';
import 'brand_tick_painter.dart';

/// Painter fallback: a scale-pop of either the brand heart glyph or a drawn
/// success/add-on tick.
class BrandMomentFallback extends StatelessWidget {
  const BrandMomentFallback({
    super.key,
    required this.kind,
    required this.size,
    required this.anim,
  });

  final BrandMomentKind kind;
  final double size;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    if (kind == BrandMomentKind.heart || kind == BrandMomentKind.followStore) {
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: anim, curve: AppMotion.emphasized)),
        child: Image.asset(
          JameiaAssets.shopRedHeart,
          width: size,
          height: size,
        ),
      );
    }
    final color = kind == BrandMomentKind.paySuccess
        ? AppColors.success
        : AppColors.primary;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, _) => CustomPaint(
          size: Size.square(size),
          painter: BrandTickPainter(anim.value, color),
        ),
      ),
    );
  }
}
