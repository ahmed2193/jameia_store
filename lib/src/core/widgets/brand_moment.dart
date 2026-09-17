import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../motion/motion.dart';
import 'brand_moment_fallback.dart';
import 'brand_moment_kind.dart';

export 'brand_moment_kind.dart';
export 'heart_pop_button.dart';

/// Jameia brand-celebration moments. The real app plays these as Lottie clips
/// baked into compiled bundles (not shipped as loose JSON in the APK), so by
/// default [BrandMoment] renders a faithful **CustomPainter + scale-pop**
/// fallback timed to the matching nominal length in [AppMotion]. If a real
/// Lottie JSON is later added, pass it via [asset] and it plays instead — the
/// widget API does not change.
///
/// Reduced-motion → the final glyph appears instantly and [onComplete] fires on
/// the next frame.
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
    return BrandMomentFallback(kind: widget.kind, size: widget.size, anim: _c);
  }
}
