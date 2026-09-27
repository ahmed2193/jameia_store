import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/motion/motion.dart';
import 'splash_beat.dart';
import 'splash_frame.dart';

/// What the finger does to the splash while it plays: a ring of colour where
/// it touches, the glow leaning towards it, and a happy hop with a flick of
/// the cape when the bag itself is tapped. Its own ticker runs only while something still moves;
/// listeners repaint the scene.
class SplashTouch extends ChangeNotifier {
  SplashTouch(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;

  /// Time on the touch clock; [_base] carries it across ticker restarts.
  Duration _now = Duration.zero;
  Duration _base = Duration.zero;
  final List<(Offset, Duration)> _taps = <(Offset, Duration)>[];
  Duration? _hopAt;
  Offset _glowTarget = Offset.zero;
  Offset _glowShift = Offset.zero;

  /// The glow moves this share of the way from the screen centre towards
  /// the finger, closing the gap with this time constant (ms) — the same
  /// feel at any frame rate.
  static const double glowFollow = 0.18;
  static const double glowEaseMs = 90;

  /// The glow counts as arrived within this many dp of its target.
  static const double glowSettled = 0.5;

  /// Tap ring size relative to a landing ring.
  static const double tapStrength = 0.8;

  /// The bag's hop when tapped (design units), its squash on take-off and
  /// the extra wave that flicks through its cape.
  static const double hopHeight = 12;
  static const double hopSquash = 0.08;
  static const double hopWave = 5;

  /// A tap ring or a hop is over after this long.
  static final double _tapMs = AppMotion.splashTapRipple.inMicroseconds / 1000;
  static final double _hopMs = AppMotion.splashMarkHop.inMicroseconds / 1000;

  double get _nowMs => _now.inMicroseconds / 1000;

  /// Offset of the glow from where the choreography puts it.
  Offset get glowShift => _glowShift;

  /// Rings of the recent taps.
  List<SplashRipple> get ripples => <SplashRipple>[
    for (final (at, start) in _taps)
      SplashRipple(
        at,
        SplashBeat.span(_nowMs, start.inMicroseconds / 1000, _tapMs),
        strength: tapStrength,
        ground: false,
      ),
  ];

  /// Extra lift of a tapped bag (design units).
  double get markLift {
    final start = _hopAt;
    if (start == null) return 0;
    return hopHeight *
        SplashBeat.arc(_nowMs, start.inMicroseconds / 1000, _hopMs);
  }

  /// Extra squash of a tapped bag: flattened as it pushes off, stretched in
  /// the air.
  double get markSquash {
    final start = _hopAt;
    if (start == null) return 0;
    final t = SplashBeat.span(_nowMs, start.inMicroseconds / 1000, _hopMs);
    if (t <= 0 || t >= 1) return 0;
    return hopSquash * math.cos(math.pi * 2 * t) * (1 - t);
  }

  /// Extra cape wave of a tapped bag (design units): a flick that fades.
  double get capeFlick {
    final start = _hopAt;
    if (start == null) return 0;
    return hopWave *
        SplashBeat.arc(_nowMs, start.inMicroseconds / 1000, _hopMs);
  }

  /// A finger went down at [position]; [onMark] when it hit the bag.
  void down(Offset position, Offset center, {required bool onMark}) {
    _taps.add((position, _now));
    if (onMark) _hopAt = _now;
    _follow(position, center);
  }

  void move(Offset position, Offset center) => _follow(position, center);

  void up() {
    _glowTarget = Offset.zero;
    _wake();
  }

  void _follow(Offset position, Offset center) {
    _glowTarget = (position - center) * glowFollow;
    _wake();
  }

  void _wake() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final previousMs = _nowMs;
    _now = _base + elapsed;
    final step = 1 - math.exp(-(_nowMs - previousMs) / glowEaseMs);
    _glowShift += (_glowTarget - _glowShift) * step;
    _taps.removeWhere((tap) => _nowMs - tap.$2.inMicroseconds / 1000 > _tapMs);
    final hop = _hopAt;
    if (hop != null && _nowMs - hop.inMicroseconds / 1000 > _hopMs) {
      _hopAt = null;
    }
    notifyListeners();
    // Nothing left to move: rest the ticker until the next touch.
    final settled = (_glowTarget - _glowShift).distance < glowSettled;
    if (_taps.isEmpty && _hopAt == null && settled) {
      _glowShift = _glowTarget;
      _base = _now;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
