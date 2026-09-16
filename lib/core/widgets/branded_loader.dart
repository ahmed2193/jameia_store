import 'package:flutter/material.dart';

import '../design/keeta_assets.dart';
import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// Branded loading indicator. Replaces bare [CircularProgressIndicator] so every
/// loader in the app shares KeeTa's look.
///
/// * Default ([BrandedLoader.new]) shows the real KeeTa brand loading GIF
///   ([KeetaAssets.brandLoadingGif], ~2.2 MB) — use for full-screen / block
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
      return _DotLoader(size: size, color: color ?? AppColors.brandForeground);
    }
    return Center(
      child: Image.asset(
        KeetaAssets.brandLoadingGif,
        width: size,
        height: size,
        gaplessPlayback: true,
        // If the GIF asset is ever missing, fall back to the dot loader rather
        // than throwing a broken-image box on a loading screen.
        errorBuilder: (_, _, _) =>
            _DotLoader(size: size * 0.5, color: AppColors.primary),
      ),
    );
  }
}

/// Three-dot pulse painted with a single [AnimationController] — cheap enough to
/// sit inside a button. Each dot scales/fades on a staggered phase.
class _DotLoader extends StatefulWidget {
  const _DotLoader({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.lottieDotLoader,
  );

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.disableAnimations) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) {
      return CustomPaint(
        size: Size(widget.size, widget.size * 0.34),
        painter: _DotPainter(0, widget.color, animate: false),
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size(widget.size, widget.size * 0.34),
          painter: _DotPainter(_c.value, widget.color),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.t, this.color, {this.animate = true});

  final double t;
  final Color color;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 3;
    final r = size.height / 2;
    final gap = (size.width - r * 2) / (count - 1);
    for (var i = 0; i < count; i++) {
      final phase = (t - i * 0.18) % 1.0;
      // 0→1→0 pulse using a smooth triangle.
      final pulse = animate ? (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0) : 0.4;
      final scale = 0.55 + 0.45 * pulse;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.4 + 0.6 * pulse)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(r + i * gap, size.height / 2), r * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) =>
      old.t != t || old.color != color;
}
