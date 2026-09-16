import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../design/keeta_assets.dart';
import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import '../theme/app_colors.dart';

/// KeeTa brand-celebration moments. The real app plays these as Lottie clips
/// baked into compiled bundles (not shipped as loose JSON in the APK), so by
/// default [BrandMoment] renders a faithful **CustomPainter + scale-pop**
/// fallback timed to the matching nominal length in [AppMotion]. If a real
/// Lottie JSON is later added, pass it via [asset] and it plays instead — the
/// widget API does not change.
///
/// Reduced-motion → the final glyph appears instantly and [onComplete] fires on
/// the next frame.
enum BrandMomentKind { heart, paySuccess, addOnDone, followStore }

class BrandMoment extends StatefulWidget {
  const BrandMoment({
    super.key,
    required this.kind,
    this.onComplete,
    this.size = 64,
    this.asset,
  });

  final BrandMomentKind kind;
  final VoidCallback? onComplete;
  final double size;

  /// Optional Lottie asset path; when non-null it plays once instead of the
  /// painter fallback.
  final String? asset;

  Duration get _nominal => switch (kind) {
    BrandMomentKind.heart => AppMotion.lottieHeart,
    BrandMomentKind.paySuccess => AppMotion.lottiePaySuccess,
    BrandMomentKind.addOnDone => AppMotion.lottieAddOnDone,
    BrandMomentKind.followStore => AppMotion.lottieFollowStore,
  };

  @override
  State<BrandMoment> createState() => _BrandMomentState();
}

class _BrandMomentState extends State<BrandMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget._nominal,
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (WidgetsBinding.instance.disableAnimations) {
        _c.value = 1;
        widget.onComplete?.call();
      } else {
        _c.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asset != null) {
      return Lottie.asset(
        widget.asset!,
        width: widget.size,
        height: widget.size,
        repeat: false,
        onLoaded: (composition) {
          _c.duration = composition.duration;
          if (!WidgetsBinding.instance.disableAnimations) _c.forward(from: 0);
        },
        controller: _c,
      );
    }
    return _PainterMoment(kind: widget.kind, size: widget.size, anim: _c);
  }
}

/// Painter fallback: a scale-pop of either the brand heart glyph or a drawn
/// success/add-on tick.
class _PainterMoment extends StatelessWidget {
  const _PainterMoment({
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
        child: Image.asset(KeetaAssets.shopRedHeart, width: size, height: size),
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
          painter: _TickPainter(anim.value, color),
        ),
      ),
    );
  }
}

/// A circle that draws itself, then a check stroke that traces in — the classic
/// success tick. [t] 0→1 drives both phases.
class _TickPainter extends CustomPainter {
  _TickPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Phase 1 (0→0.5): ring scales in. Phase 2 (0.5→1): check traces.
    final ringT = (t / 0.5).clamp(0.0, 1.0);
    final checkT = ((t - 0.5) / 0.5).clamp(0.0, 1.0);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r * ringT, ringPaint);

    if (checkT > 0) {
      final p1 = Offset(c.dx - r * 0.42, c.dy + r * 0.02);
      final mid = Offset(c.dx - r * 0.10, c.dy + r * 0.34);
      final p2 = Offset(c.dx + r * 0.44, c.dy - r * 0.30);
      final path = Path()..moveTo(p1.dx, p1.dy);
      // First leg fully drawn over the first half of checkT, second over the rest.
      if (checkT <= 0.5) {
        final f = checkT / 0.5;
        path.lineTo(p1.dx + (mid.dx - p1.dx) * f, p1.dy + (mid.dy - p1.dy) * f);
      } else {
        final f = (checkT - 0.5) / 0.5;
        path.lineTo(mid.dx, mid.dy);
        path.lineTo(
          mid.dx + (p2.dx - mid.dx) * f,
          mid.dy + (p2.dy - mid.dy) * f,
        );
      }
      final checkPaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TickPainter old) =>
      old.t != t || old.color != color;
}

/// Favorite / wishlist toggle with KeeTa's heart pop. Tapping flips [liked] and
/// pops the heart glyph (filled-red when liked, empty when not). Uses
/// [PressScale] for the tap feel and [PopScale] for the swap pop.
class HeartPopButton extends StatelessWidget {
  const HeartPopButton({
    super.key,
    required this.liked,
    required this.onChanged,
    this.size = 24,
  });

  final bool liked;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => onChanged(!liked),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: PopScale(
          popKey: liked,
          child: Image.asset(
            liked ? KeetaAssets.shopRedHeart : KeetaAssets.shopEmptyHeart,
            width: size,
            height: size,
          ),
        ),
      ),
    );
  }
}
