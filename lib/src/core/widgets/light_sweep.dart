import 'package:flutter/material.dart';

import '../motion/ambient_loop.dart';
import '../motion/motion.dart';
import 'light_sweep_band.dart';

/// A soft diagonal band of light that sweeps across [child] from the start
/// edge to the end edge, then rests, once every [period] (a CTA's shine, a
/// chip's glint, a member card's holographic sheen). Paint-only — a
/// fractional translation of one gradient box in its own `RepaintBoundary`,
/// no image decoding — clipped to the child's box (or [borderRadius]),
/// ignores touches and mirrors in RTL. Only the sweep ticks: the rest is a
/// timer, so no frame is drawn between sweeps.
///
/// An [AmbientLoop] preset (docs/motion §9.4 #22, D19): at most
/// [maxPasses] passes within [AppMotion.ambientBudget] each time it comes on
/// screen, and at most one sweep per screen (another one on the same route
/// stays still while it plays). Off while ![active], off screen, on a hidden
/// tab, in the background and with a screen reader; nothing at all under
/// reduced motion. [LightSweep.progress] is the exempt kind: a shimmer that
/// shows work in progress keeps sweeping while it is seen.
class LightSweep extends StatelessWidget {
  const LightSweep({
    super.key,
    required this.child,
    this.active = true,
    this.period = AppMotion.sheen,
    this.sweepShare = defaultSweepShare,
    this.peakAlpha = LightSweepBand.defaultPeakAlpha,
    this.borderRadius,
  }) : progress = false;

  /// A shimmer over work in progress (a "redeeming…" veil): unbounded,
  /// shared with no other sweep. Still gated off screen and when reduced.
  const LightSweep.progress({
    super.key,
    required this.child,
    this.period = AppMotion.shimmer,
    this.sweepShare = 1,
    this.peakAlpha = LightSweepBand.defaultPeakAlpha,
    this.borderRadius,
  }) : active = true,
       progress = true;

  /// Share of each [period] the sweep takes; the rest is a pause. Two
  /// passes of the default [AppMotion.sheen] fit the ambient budget
  /// (1.37 s + 2.23 s + 1.37 s < 5 s).
  static const double defaultSweepShare = 0.38;

  /// Most passes per appearance.
  static const int maxPasses = 2;

  final Widget child;
  final bool active;
  final Duration period;
  final double sweepShare;

  /// Brightness of the band's centre (white at this opacity).
  final double peakAlpha;
  final BorderRadius? borderRadius;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final sweep = period * sweepShare;
    // The child keeps its place in the tree whether the sweep runs or not,
    // so toggling [active] never rebuilds its state.
    return AmbientLoop(
      period: sweep,
      rest: period - sweep,
      curve: AppMotion.machEaseInOut,
      maxLaps: progress ? null : maxPasses,
      budget: progress ? null : AppMotion.ambientBudget,
      exclusive: !progress,
      active: active,
      child: child,
      builder: (context, loop, child) => Stack(
        fit: StackFit.passthrough,
        children: [
          child!,
          if (active && !MotionGuard.reduced(context))
            Positioned.fill(
              child: LightSweepBand(
                sweep: loop,
                peakAlpha: peakAlpha,
                borderRadius: borderRadius,
              ),
            ),
        ],
      ),
    );
  }
}
