import 'dart:async';

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import 'light_sweep_band.dart';

/// A soft diagonal band of light that sweeps across [child] from the start
/// edge to the end edge, then rests, once every [period] (a CTA's shine, a
/// chip's glint, a member card's holographic sheen). Paint-only — a
/// fractional translation of one gradient box in its own `RepaintBoundary`,
/// no image decoding — clipped to the child's box (or [borderRadius]),
/// ignores touches and mirrors in RTL. Only the sweep ticks: the rest is a
/// timer, so no frame is drawn between sweeps. Off while ![active]; nothing
/// at all under reduced motion.
class LightSweep extends StatefulWidget {
  const LightSweep({
    super.key,
    required this.child,
    this.active = true,
    this.period = AppMotion.sheen,
    this.sweepShare = defaultSweepShare,
    this.peakAlpha = LightSweepBand.defaultPeakAlpha,
    this.borderRadius,
  });

  /// Share of each [period] the sweep takes; the rest is a pause.
  static const double defaultSweepShare = 0.4;

  final Widget child;
  final bool active;
  final Duration period;
  final double sweepShare;

  /// Brightness of the band's centre (white at this opacity).
  final double peakAlpha;
  final BorderRadius? borderRadius;

  @override
  State<LightSweep> createState() => _LightSweepState();
}

class _LightSweepState extends State<LightSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _sweepDuration,
  )..addStatusListener(_onStatus);
  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.machEaseInOut,
  );

  /// The pause before the next sweep; `null` while sweeping or stopped.
  Timer? _rest;

  Duration get _sweepDuration => widget.period * widget.sweepShare;
  Duration get _restDuration => widget.period * (1 - widget.sweepShare);

  bool get _runs => widget.active && !MotionGuard.reduced(context);

  /// A finished sweep leaves the band parked off the end edge and waits
  /// out the rest of the period before the next one.
  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _rest?.cancel();
    _rest = Timer(_restDuration, () {
      _rest = null;
      if (mounted && _runs) _controller.forward(from: 0);
    });
  }

  void _stop() {
    _rest?.cancel();
    _rest = null;
    _controller
      ..stop()
      ..value = 0;
  }

  void _sync() {
    if (_runs) {
      if (!_controller.isAnimating && _rest == null) {
        _controller.forward(from: 0);
      }
    } else {
      _stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LightSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.sweepShare != widget.sweepShare) {
      // A new rhythm starts over from a fresh sweep.
      _controller.duration = _sweepDuration;
      _stop();
    }
    _sync();
  }

  @override
  void dispose() {
    _rest?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The child keeps its place in the tree whether the sweep runs or not,
    // so toggling [LightSweep.active] never rebuilds its state.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_runs)
          Positioned.fill(
            child: LightSweepBand(
              sweep: _sweep,
              peakAlpha: widget.peakAlpha,
              borderRadius: widget.borderRadius,
            ),
          ),
      ],
    );
  }
}
