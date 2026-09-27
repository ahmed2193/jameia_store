import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import 'assistant_mascot_hop.dart';
import 'assistant_mascot_mood.dart';
import 'assistant_mascot_painter.dart';
import 'assistant_mascot_pose.dart';

/// The assistant's face: a painted mascot that eases between [mood]s, looks
/// where it is told ([look]), hops for joy whenever [cheer] changes and —
/// while [alive] — blinks and glances around on its own.
///
/// Nothing loops: each gesture runs a short controller and stops, so a
/// mascot at rest draws no frames. Timers pause with the route (`TickerMode`)
/// and reduced motion leaves a still face that only swaps expressions.
/// Decorative for screen readers: whatever holds it says what it does.
class AssistantMascot extends StatefulWidget {
  const AssistantMascot({
    super.key,
    this.size = AppSize.s56,
    this.mood = AssistantMascotMood.idle,
    this.look = Offset.zero,
    this.outlined = false,
    this.alive = true,
    this.cheer,
  });

  final double size;
  final AssistantMascotMood mood;

  /// Where to look, each axis in `-1..1`; zero lets it glance on its own.
  final Offset look;

  /// White sticker rim, for a mascot floating over content.
  final bool outlined;

  /// Blinks and glances on its own.
  final bool alive;

  /// Every new value plays one happy hop.
  final Object? cheer;

  @override
  State<AssistantMascot> createState() => _AssistantMascotState();
}

class _AssistantMascotState extends State<AssistantMascot>
    with TickerProviderStateMixin {
  static const Duration _blinkHalf = Duration(milliseconds: 75);
  static const Duration _moodEase = Duration(milliseconds: 260);
  static const Duration _mouthFlap = Duration(milliseconds: 150);
  static const Duration _hopLength = Duration(milliseconds: 720);
  static const Duration _lookEase = Duration(milliseconds: 240);
  static const Duration _glanceHold = Duration(milliseconds: 900);

  static const int _blinkMinMs = 3000;
  static const int _blinkSpreadMs = 4000;
  static const double _doubleBlinkChance = 0.2;
  static const int _glanceMinMs = 15000;
  static const int _glanceSpreadMs = 10000;
  static const double _glanceReach = 0.85;
  static const double _glanceLift = 0.25;
  static const double _hopHeightRatio = 0.16;
  static const double _swayWithLook = 0.35;
  static const double _talkRest = 0.15;

  final math.Random _random = math.Random();

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: _blinkHalf,
  );
  late final AnimationController _mood = AnimationController(
    vsync: this,
    duration: _moodEase,
    value: 1,
  );
  late final AnimationController _mouth = AnimationController(
    vsync: this,
    duration: _mouthFlap,
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: _hopLength,
  );
  late final AnimationController _eyes = AnimationController(
    vsync: this,
    duration: _lookEase,
    value: 1,
  );
  late final Listenable _frame = Listenable.merge([
    _blink,
    _mood,
    _mouth,
    _hop,
    _eyes,
  ]);

  late AssistantMascotPose _moodFrom = widget.mood.pose;
  Offset _lookFrom = Offset.zero;
  late Offset _lookTo = widget.look;

  Timer? _blinkTimer;
  Timer? _glanceTimer;
  bool _ambient = false;
  bool _reduced = false;
  bool _onScreen = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionGuard.reduced(context);
    _onScreen = TickerMode.valuesOf(context).enabled;
    _syncAmbient(widget.alive && !_reduced && _onScreen);
    _syncMouth();
  }

  @override
  void didUpdateWidget(AssistantMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _moodFrom = _currentMood(oldWidget.mood);
      _run(_mood);
      _syncMouth();
    }
    if (oldWidget.look != widget.look) _lookAt(widget.look);
    if (oldWidget.cheer != widget.cheer && widget.cheer != null) _run(_hop);
    if (oldWidget.alive != widget.alive) {
      _syncAmbient(widget.alive && !_reduced && _onScreen);
    }
  }

  /// The mood face as it is on screen right now (mid-ease included).
  AssistantMascotPose _currentMood(AssistantMascotMood target) =>
      AssistantMascotPose.lerp(
        _moodFrom,
        target.pose,
        AppMotion.signature.transform(_mood.value),
      );

  /// Plays [controller] from the start, or jumps to its end under reduced
  /// motion (a hop then simply does not happen).
  void _run(AnimationController controller) {
    if (_reduced) {
      controller.value = controller == _hop ? 0 : 1;
      return;
    }
    controller.forward(from: 0);
  }

  void _syncMouth() {
    if (widget.mood == AssistantMascotMood.talking && !_reduced) {
      if (!_mouth.isAnimating) _mouth.repeat(reverse: true);
    } else {
      _mouth
        ..stop()
        ..value = 0;
    }
  }

  void _syncAmbient(bool on) {
    if (on == _ambient) return;
    _ambient = on;
    _blinkTimer?.cancel();
    _glanceTimer?.cancel();
    if (on) {
      _scheduleBlink();
      _scheduleGlance();
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: _blinkMinMs + _random.nextInt(_blinkSpreadMs)),
      () async {
        await _blinkOnce();
        if (_random.nextDouble() < _doubleBlinkChance) await _blinkOnce();
        if (mounted && _ambient) _scheduleBlink();
      },
    );
  }

  Future<void> _blinkOnce() async {
    if (!mounted) return;
    await _blink.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted) return;
    await _blink.reverse().orCancel.catchError((_) {});
  }

  void _scheduleGlance() {
    _glanceTimer = Timer(
      Duration(milliseconds: _glanceMinMs + _random.nextInt(_glanceSpreadMs)),
      () {
        if (!mounted || !_ambient) return;
        final free =
            widget.look == Offset.zero && widget.mood.pose.look == Offset.zero;
        if (!free) {
          _scheduleGlance();
          return;
        }
        final side = _random.nextBool() ? 1.0 : -1.0;
        _lookAt(Offset(side * _glanceReach, -_glanceLift));
        _glanceTimer = Timer(_glanceHold, () {
          if (!mounted) return;
          _lookAt(widget.look);
          if (_ambient) _scheduleGlance();
        });
      },
    );
  }

  void _lookAt(Offset target) {
    _lookFrom = _currentLook();
    _lookTo = target;
    _run(_eyes);
  }

  Offset _currentLook() => Offset.lerp(
    _lookFrom,
    _lookTo,
    AppMotion.signature.transform(_eyes.value),
  )!;

  AssistantMascotPose _pose() {
    final mood = _currentMood(widget.mood);
    final hop = _hop.value;
    final hopping = _hop.isAnimating;
    final joy = hopping ? AssistantMascotHop.joy(hop) : 0.0;
    final look = mood.look + _currentLook();
    return AssistantMascotPose(
      blink: _blink.value,
      happy: math.max(mood.happy, joy),
      talk: widget.mood == AssistantMascotMood.talking
          ? _talkRest + (1 - _talkRest) * _mouth.value
          : mood.talk,
      look: look,
      squash: mood.squash + (hopping ? AssistantMascotHop.squash(hop) : 0),
      sway:
          mood.sway +
          look.dx * _swayWithLook +
          (hopping ? AssistantMascotHop.sway(hop) : 0),
      twinkle: math.max(mood.twinkle, joy),
      surprise: mood.surprise,
    );
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _glanceTimer?.cancel();
    _blink.dispose();
    _mood.dispose();
    _mouth.dispose();
    _hop.dispose();
    _eyes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _frame,
          builder: (context, _) => Transform.translate(
            offset: Offset(
              0,
              _hop.isAnimating
                  ? -AssistantMascotHop.lift(_hop.value) *
                        size *
                        _hopHeightRatio
                  : 0,
            ),
            child: CustomPaint(
              size: Size.square(size),
              painter: AssistantMascotPainter(
                pose: _pose(),
                outlined: widget.outlined,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
