import 'package:flutter/material.dart';

import 'ambient_loop.dart';
import 'motion.dart';

/// Idle FLOAT — an [AmbientLoop] preset (D14). Bobs [child] up by
/// [amplitude] logical pixels and back over one [period] (each leg is half
/// of it), [AppMotion.machEaseInOut]. [FloatLoop.glow] is the breathing-glow
/// preset (the retired `GlowPulse`): a soft disc whose opacity and scale
/// swell and ease back over the same cycle.
///
/// Like every ambient loop it plays whole cycles for at most
/// [AppMotion.ambientBudget] each time it comes on screen, stops off screen,
/// on a hidden tab, in the background, under reduced motion and with a
/// screen reader (still: the resting pose), and repaints only its own
/// layer. A [count] of legs plays once for the widget's life (a hint
/// bubble), rounded up to whole cycles so it rests where it started.
class FloatLoop extends StatelessWidget {
  const FloatLoop({
    super.key,
    required Widget this.child,
    this.amplitude = defaultAmplitude,
    this.period = AppMotion.floatLoop,
    this.count,
    this.phase = 0,
    this.active = true,
  }) : color = null,
       diameter = 0,
       minOpacity = 1,
       maxOpacity = 1,
       maxScale = 1;

  /// A soft [color] disc of [diameter] breathing between [minOpacity] / 1.0
  /// and [maxOpacity] / [maxScale]; a radial gradient (no blur layer),
  /// ignoring touches. At rest it shows [minOpacity].
  const FloatLoop.glow({
    super.key,
    required Color this.color,
    required this.diameter,
    this.minOpacity = defaultMinOpacity,
    this.maxOpacity = defaultMaxOpacity,
    this.maxScale = defaultMaxScale,
    this.period = AppMotion.floatLoop,
    this.active = true,
  }) : child = null,
       amplitude = 0,
       count = null,
       phase = 0;

  static const double defaultAmplitude = 4;
  static const double defaultMinOpacity = 0.45;
  static const double defaultMaxOpacity = 0.75;
  static const double defaultMaxScale = 1.08;

  final Widget? child;
  final double amplitude;

  /// One full cycle, up AND back.
  final Duration period;

  /// Legs to play (one leg = up OR back down), once; `null` = whole cycles
  /// within the ambient budget on every appearance.
  final int? count;

  /// Where in the cycle (0–1) it starts, so neighbours keep apart.
  final double phase;

  /// False holds the resting pose (e.g. until its card has landed).
  final bool active;

  final Color? color;
  final double diameter;
  final double minOpacity;
  final double maxOpacity;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final legs = count;
    final glow = color;
    if (glow == null) {
      return AmbientLoop.value(
        period: period,
        reverse: true,
        curve: AppMotion.machEaseInOut,
        phase: phase,
        maxLaps: legs == null ? null : (legs + 1) ~/ 2,
        replay: legs == null,
        active: active,
        valueBuilder: (context, t, child) => Transform.translate(
          offset: Offset(0, -amplitude * t),
          child: child,
        ),
        child: child!,
      );
    }
    final disc = SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [glow, glow.withValues(alpha: 0)]),
        ),
      ),
    );
    return IgnorePointer(
      child: RepaintBoundary(
        child: AmbientLoop(
          period: period,
          reverse: true,
          curve: AppMotion.machEaseInOut,
          active: active,
          child: disc,
          // Transitions, not a rebuilt Opacity per frame (PB-18).
          builder: (context, loop, disc) => FadeTransition(
            opacity: loop.drive(
              Tween<double>(begin: minOpacity, end: maxOpacity),
            ),
            child: ScaleTransition(
              scale: loop.drive(Tween<double>(begin: 1, end: maxScale)),
              child: disc,
            ),
          ),
        ),
      ),
    );
  }
}
