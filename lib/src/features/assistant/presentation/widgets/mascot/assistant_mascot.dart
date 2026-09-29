import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../assistant_motion.dart';
import '../buddy/buddy_motion_gate.dart';
import 'assistant_mascot_gesture.dart';
import 'assistant_mascot_hop.dart';
import 'assistant_mascot_mood.dart';
import 'assistant_mascot_painter.dart';
import 'assistant_mascot_pose.dart';

/// The assistant's face: a painted mascot that eases between [mood]s, looks
/// where it is told ([look]), hops for joy whenever [cheer] changes, waves
/// its sprout whenever [wave] changes and winks whenever [wink] changes.
///
/// It is STILL by default (docs/motion §9.6 §2.1): it never blinks or
/// glances on its own. A new [wake] value opens a wake window — one blink
/// ([AssistantMotion.wakeBlinkDelay] later, now and then a double one), at
/// most one per [AssistantMotion.wakeBlinkGap] — and that is all.
///
/// Every motion asks [BuddyMotionGate.mayMoveOf] before it starts (not
/// while the customer types, scrolls, reads a streaming answer or records,
/// not under a covering page, reduced motion or a screen reader): a closed
/// gate swaps the face in place and plays no gesture. Nothing loops — each
/// gesture runs a short controller and stops, so a mascot at rest draws no
/// frames; its only timer (the wake blink) is cancelled whenever it may not
/// move. Decorative for screen readers: whatever holds it says what it does.
class AssistantMascot extends StatefulWidget {
  const AssistantMascot({
    super.key,
    this.size = AppSize.s56,
    this.mood = AssistantMascotMood.idle,
    this.look = Offset.zero,
    this.outlined = false,
    this.wake,
    this.cheer,
    this.wave,
    this.wink,
  });

  final double size;
  final AssistantMascotMood mood;

  /// Where to look, each axis in `-1..1`.
  final Offset look;

  /// White sticker rim, for a mascot floating over content.
  final bool outlined;

  /// Every new value opens a wake window (one blink at most).
  final Object? wake;

  /// Every new value plays one happy hop.
  final Object? cheer;

  /// Every new value waves the sprout once (hello).
  final Object? wave;

  /// Every new value plays one wink.
  final Object? wink;

  @override
  State<AssistantMascot> createState() => _AssistantMascotState();
}

class _AssistantMascotState extends State<AssistantMascot>
    with TickerProviderStateMixin {
  static const double _hopHeightRatio = 0.16;
  static const double _swayWithLook = 0.35;

  final math.Random _random = math.Random();

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: AssistantMotion.blinkHalf,
  );
  late final AnimationController _mood = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: AssistantMotion.hop,
  );
  late final AnimationController _eyes = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: AssistantMotion.wave,
  );
  late final AnimationController _wink = AnimationController(
    vsync: this,
    duration: AssistantMotion.wink,
  );
  late final Listenable _frame = Listenable.merge([
    _blink,
    _mood,
    _hop,
    _eyes,
    _wave,
    _wink,
  ]);

  late AssistantMascotPose _moodFrom = widget.mood.pose;
  Offset _lookFrom = Offset.zero;
  late Offset _lookTo = widget.look;

  /// A motion may start now (gate open, motion allowed).
  bool _mayMove = false;
  Timer? _wakeBlink;

  /// A blink happened less than [AssistantMotion.wakeBlinkGap] ago.
  Timer? _blinkRest;

  @override
  void initState() {
    super.initState();
    // A mascot that mounts with a wake (a header on a new page) opens it.
    if (widget.wake != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _woken();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mayMove = BuddyMotionGate.mayMoveOf(context);
    if (!_mayMove) _wakeBlink?.cancel();
  }

  @override
  void didUpdateWidget(AssistantMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _moodFrom = _currentMood(oldWidget.mood);
      _run(_mood, gesture: false);
    }
    if (oldWidget.look != widget.look) _lookAt(widget.look);
    if (oldWidget.cheer != widget.cheer && widget.cheer != null) _run(_hop);
    if (oldWidget.wave != widget.wave && widget.wave != null) _run(_wave);
    if (oldWidget.wink != widget.wink && widget.wink != null) _run(_wink);
    if (oldWidget.wake != widget.wake && widget.wake != null) _woken();
  }

  /// The mood face as it is on screen right now (mid-ease included).
  AssistantMascotPose _currentMood(AssistantMascotMood target) =>
      AssistantMascotPose.lerp(
        _moodFrom,
        target.pose,
        AppMotion.signature.transform(_mood.value),
      );

  /// Plays [controller] from the start. When the mascot may not move a
  /// [gesture] (hop, wave, wink) simply does not happen and an ease (mood,
  /// eyes) jumps to its end.
  void _run(AnimationController controller, {bool gesture = true}) {
    if (!_mayMove) {
      controller
        ..stop()
        ..value = gesture ? 0 : 1;
      return;
    }
    controller.forward(from: 0);
  }

  /// A wake: one blink a moment later, unless one came lately. Whether it
  /// may move is asked when the blink is due (a gate that opens this frame
  /// is read after the new wake arrives), and a gate that closes meanwhile
  /// cancels it.
  void _woken() {
    if (_blinkRest != null) return;
    _wakeBlink?.cancel();
    _wakeBlink = Timer(AssistantMotion.wakeBlinkDelay, () async {
      if (!mounted || !_mayMove) return;
      _blinkRest = Timer(AssistantMotion.wakeBlinkGap, () => _blinkRest = null);
      await _blinkOnce();
      if (_random.nextDouble() < AssistantMotion.doubleBlinkChance) {
        await _blinkOnce();
      }
    });
  }

  Future<void> _blinkOnce() async {
    if (!mounted) return;
    await _blink.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted) return;
    await _blink.reverse().orCancel.catchError((_) {});
  }

  void _lookAt(Offset target) {
    _lookFrom = _currentLook();
    _lookTo = target;
    _run(_eyes, gesture: false);
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
      talk: mood.talk,
      look: look,
      squash: mood.squash + (hopping ? AssistantMascotHop.squash(hop) : 0),
      sway:
          mood.sway +
          look.dx * _swayWithLook +
          (hopping ? AssistantMascotHop.sway(hop) : 0) +
          (_wave.isAnimating ? AssistantMascotGesture.wave(_wave.value) : 0),
      twinkle: math.max(mood.twinkle, joy),
      surprise: mood.surprise,
      wink: _wink.isAnimating ? AssistantMascotGesture.wink(_wink.value) : 0,
    );
  }

  @override
  void dispose() {
    _wakeBlink?.cancel();
    _blinkRest?.cancel();
    _blink.dispose();
    _mood.dispose();
    _hop.dispose();
    _eyes.dispose();
    _wave.dispose();
    _wink.dispose();
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
