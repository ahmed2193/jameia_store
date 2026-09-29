import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'confetti_painter.dart';
import 'motion.dart';

/// CELEBRATION — a one-shot confetti burst over [child], played every time
/// [playKey] changes to a new non-null value (a subscription that just went
/// through, a reward applied). Pieces come from a fixed seed, so a burst looks
/// the same every time and tests stay deterministic. The overlay ignores
/// touches and paints nothing while idle. Reduced motion → no burst.
/// [playing] tells a reaction that must not compete with a burst (the
/// assistant buddy's hop) to wait until it is over.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.playKey,
    required this.colors,
    required this.child,
    this.origin = defaultOrigin,
    this.count = defaultCount,
  });

  /// Launch point as fractions of the overlay size (centre, a third down).
  static const Offset defaultOrigin = Offset(0.5, 0.33);
  static const int defaultCount = 48;

  static int _bursts = 0;
  static final ValueNotifier<bool> _playing = ValueNotifier<bool>(false);

  /// Whether a burst is in the air anywhere in the app.
  static ValueListenable<bool> get playing => _playing;

  static void _count(int delta, {bool later = false}) {
    _bursts += delta;
    void apply() => _playing.value = _bursts > 0;
    // From `dispose` (mid tree teardown) nothing may rebuild synchronously.
    if (later) {
      scheduleMicrotask(apply);
    } else {
      apply();
    }
  }

  final Object? playKey;
  final List<Color> colors;
  final Widget child;
  final Offset origin;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const int _seed = 7;
  static const double _spread = math.pi * 0.9;
  static const double _minSpeed = 0.9;
  static const double _speedRange = 0.8;
  static const double _maxSpin = 12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.confetti,
  )..addStatusListener(_onStatus);

  /// This burst is counted in [ConfettiBurst.playing].
  bool _counted = false;

  void _onStatus(AnimationStatus status) {
    if (status.isCompleted) _release();
  }

  void _release({bool later = false}) {
    if (!_counted) return;
    _counted = false;
    ConfettiBurst._count(-1, later: later);
  }

  late final List<ConfettiPiece> _pieces = _buildPieces();

  List<ConfettiPiece> _buildPieces() {
    final colors = widget.colors;
    if (colors.isEmpty) return const <ConfettiPiece>[];
    final random = math.Random(_seed);
    return List<ConfettiPiece>.generate(widget.count, (i) {
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * _spread;
      return ConfettiPiece(
        angle: angle,
        speed: _minSpeed + random.nextDouble() * _speedRange,
        spin: (random.nextDouble() - 0.5) * _maxSpin,
        color: colors[i % colors.length],
        isRound: i.isOdd,
      );
    }, growable: false);
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playKey != null &&
        widget.playKey != oldWidget.playKey &&
        !MotionGuard.reduced(context)) {
      if (!_counted) {
        _counted = true;
        ConfettiBurst._count(1);
      }
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _release(later: true);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ConfettiPainter(
                  pieces: _pieces,
                  progress: _controller,
                  origin: widget.origin,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
