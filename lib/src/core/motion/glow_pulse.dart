import 'package:flutter/material.dart';

import 'motion.dart';

/// Breathing GLOW — a soft [color] disc of [diameter] whose opacity and scale
/// pulse between [minOpacity]/1.0 and [maxOpacity]/[maxScale] over
/// [AppMotion.glowPulse] (the website's `.animate-pro-glow`). Drawn with a
/// radial gradient (no `BackdropFilter` / blur layer), paint-only, in a
/// `RepaintBoundary`. Reduced motion → a still glow at [minOpacity].
class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.color,
    required this.diameter,
    this.minOpacity = defaultMinOpacity,
    this.maxOpacity = defaultMaxOpacity,
    this.maxScale = defaultMaxScale,
  });

  static const double defaultMinOpacity = 0.45;
  static const double defaultMaxOpacity = 0.75;
  static const double defaultMaxScale = 1.08;

  final Color color;
  final double diameter;
  final double minOpacity;
  final double maxOpacity;
  final double maxScale;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  // One period of the CSS keyframes = there and back, so each half is half.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.glowPulse ~/ 2,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.machEaseInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionGuard.reduced(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disc = SizedBox.square(
      dimension: widget.diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [widget.color, widget.color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _curve,
          child: disc,
          builder: (context, child) {
            final t = _curve.value;
            return Opacity(
              opacity:
                  widget.minOpacity +
                  (widget.maxOpacity - widget.minOpacity) * t,
              child: Transform.scale(
                scale: 1 + (widget.maxScale - 1) * t,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
