import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/confetti_burst.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_thought.dart';
import '../assistant_motion.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_buddy_thought_bubble.dart';
import 'assistant_buddy_thought_face.dart';
import 'assistant_buddy_thought_phase.dart';
import 'buddy_motion_gate.dart';

/// The floating mascot that opens the chat: tap to chat, drag it anywhere
/// (it settles on the nearest side), hold it to hide it for today. It
/// steps off its edge while not [shown] (scrolling down, the greeting on
/// screen). Now and then it thinks out loud ([thought]) in a small bubble
/// over its head; a tap on the line opens the chat ([onThoughtTap]).
///
/// Alive but not childish (docs/motion §9.6 §3.1): still until something
/// happens, it reacts once and goes still again, and only while
/// [BuddyMotionGate] lets it —
/// * a WAKE (it arrives, its tab or the shell comes back into view, the
///   customer stops typing or scrolling, the first touch after a quiet
///   while) lets it blink once;
/// * it looks towards a touch at most every `lookGap`;
/// * it hops when [cheers] ticks (a cart add — after the flight in the air
///   has landed —, the greeting or the tour handing back) and when a drag
///   lands: at most one hop per `hopGap` and `hopsPerVisit` a [visit];
/// * it waves as the visit's greeting line starts and winks at a line of
///   company, holding a still talking pose while its line reveals.
///
/// A drag always follows the finger. Presence and drag are paint-only
/// (transforms); reduced motion turns the arrival into a fade in place and
/// the landing into a jump. Rests at the end side above the home's
/// back-to-top button, so the two never cover each other.
class AssistantBuddyLauncher extends StatefulWidget {
  const AssistantBuddyLauncher({
    super.key,
    required this.shown,
    required this.cheers,
    this.visit = 0,
    this.thought,
    required this.onThoughtSaid,
    required this.onThoughtDone,
    required this.touches,
    required this.onOpen,
    required this.onThoughtTap,
    required this.onHide,
  });

  final bool shown;
  final int cheers;

  /// The customer's visit: its hops are counted afresh when it changes.
  final int visit;

  /// The line it is thinking out loud, `null` when none.
  final AssistantThought? thought;
  final ValueChanged<AssistantThought> onThoughtSaid;
  final ValueChanged<AssistantThought> onThoughtDone;

  /// Global positions of the latest touches over the shell.
  final ValueListenable<Offset?> touches;
  final VoidCallback onOpen;
  final ValueChanged<AssistantThought> onThoughtTap;
  final Future<void> Function() onHide;

  @override
  State<AssistantBuddyLauncher> createState() => _AssistantBuddyLauncherState();
}

class _AssistantBuddyLauncherState extends State<AssistantBuddyLauncher>
    with TickerProviderStateMixin {
  static const double _box = AppSize.s64;
  static const double _edge = AppSpacing.s8;
  static const double _restBottom = AppSize.s68;
  static const double _minBottom = AppSpacing.s8;
  static const double _topRoom = AppSize.s120;
  static const double _hiddenScale = 0.6;
  static const double _flingSpeed = 600;
  static const double _lookReach = 160;
  static const Duration _joyHold = Duration(milliseconds: 900);
  static const double _thoughtGap = AppSpacing.s2;
  static const Animation<double> _opaque = AlwaysStoppedAnimation<double>(1);

  final GlobalKey _mascotKey = GlobalKey();

  late final AnimationController _presence = AnimationController(
    vsync: this,
    value: widget.shown ? 1 : 0,
  );
  late final CurvedAnimation _presenceCurve = CurvedAnimation(
    parent: _presence,
    curve: AppMotion.signature,
    reverseCurve: AppMotion.exit,
  );
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: AppSprings.calm.duration,
  );
  late final CurvedAnimation _settle = CurvedAnimation(
    parent: _snap,
    curve: AppSprings.calm,
  );

  /// Top-left while dragged or settling on its spot; `null` at rest. A
  /// notifier, so a drag moves the mascot without rebuilding the layer.
  final ValueNotifier<Offset?> _drag = ValueNotifier<Offset?>(null);

  /// Resting spot: which side (reading direction) and how high.
  bool _atEnd = true;
  double _bottom = _restBottom;
  Offset _snapFrom = Offset.zero;
  Offset _snapTo = Offset.zero;

  bool _pressed = false;
  bool _reduced = false;
  AssistantMascotMood _mood = AssistantMascotMood.idle;
  Offset _look = Offset.zero;
  (AssistantThought, AssistantBuddyThoughtPhase)? _thinking;

  /// What the mascot is asked to play: a new value is one wake / hop /
  /// wave / wink.
  int _wakes = 0;
  int _hops = 0;
  int _waves = 0;
  int _winks = 0;

  bool _mayMove = false;
  bool _gateRead = false;
  bool _idle = false;
  bool _hopWaiting = false;
  int _hopsThisVisit = 0;
  Timer? _lookBack;
  Timer? _lookRest;
  Timer? _hopRest;
  Timer? _idleTimer;
  Timer? _joyTimer;

  @override
  void initState() {
    super.initState();
    widget.touches.addListener(_onTouch);
    FlyToCart.inFlight.addListener(_onFlight);
    ConfettiBurst.playing.addListener(_onFlight);
    _armIdle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionGuard.reduced(context);
    final may = BuddyMotionGate.mayMoveOf(context);
    // Back to calm (typing, scrolling, a page on top, the app away — the
    // gate holds a settle after each): a new wake.
    if (may && !_mayMove && _gateRead) _wakes++;
    if (!may) _lookRest?.cancel();
    _mayMove = may;
    _gateRead = true;
  }

  @override
  void didUpdateWidget(AssistantBuddyLauncher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.touches != widget.touches) {
      oldWidget.touches.removeListener(_onTouch);
      widget.touches.addListener(_onTouch);
    }
    if (oldWidget.visit != widget.visit) _hopsThisVisit = 0;
    if (oldWidget.shown != widget.shown) {
      final fade = _reduced ? AppMotion.fast : null;
      if (widget.shown) {
        _wakes++;
        _presence.animateTo(1, duration: fade ?? AppMotion.page);
      } else {
        _presence.animateBack(0, duration: fade ?? AppMotion.medium);
      }
    }
    if (oldWidget.cheers != widget.cheers) _requestHop();
  }

  void _armIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(AssistantMotion.wakeAfterIdle, () => _idle = true);
  }

  /// A finger went down over the shell: after a quiet while that wakes the
  /// mascot; its eyes follow it for a moment, now and then.
  void _onTouch() {
    if (_idle) {
      _idle = false;
      setState(() => _wakes++);
    }
    _armIdle();
    final touch = widget.touches.value;
    final box = _mascotKey.currentContext?.findRenderObject();
    if (touch == null ||
        !widget.shown ||
        !_mayMove ||
        _lookRest != null ||
        _drag.value != null ||
        box is! RenderBox) {
      return;
    }
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final delta = touch - center;
    if (delta.distance < _box) return; // a tap on the mascot itself
    final reach = (delta.distance / _lookReach).clamp(0.0, 1.0);
    setState(() => _look = delta / delta.distance * reach);
    _lookRest = Timer(AssistantMotion.lookGap, () => _lookRest = null);
    _lookBack?.cancel();
    _lookBack = Timer(AssistantMotion.lookHold, () {
      if (mounted) setState(() => _look = Offset.zero);
    });
  }

  /// Another primary motion plays: a thumbnail flying to the cart, or a
  /// confetti burst.
  static bool get _anotherPlays =>
      FlyToCart.inFlight.value || ConfettiBurst.playing.value;

  /// A reason to hop: dropped while it must stay still, held while another
  /// primary motion plays (one hop waits for it to end — a landing, the
  /// confetti falling), and spaced out — one per `hopGap`, `hopsPerVisit`
  /// a visit.
  void _requestHop() {
    if (!_mayMove) return;
    if (_anotherPlays) {
      _hopWaiting = true;
      return;
    }
    if (_hopRest != null || _hopsThisVisit >= AssistantMotion.hopsPerVisit) {
      return;
    }
    _hopsThisVisit++;
    _hopRest = Timer(AssistantMotion.hopGap, () => _hopRest = null);
    setState(() => _hops++);
  }

  void _onFlight() {
    if (_anotherPlays || !_hopWaiting || !mounted) return;
    _hopWaiting = false;
    _requestHop();
  }

  void _rejoice() {
    setState(() => _mood = AssistantMascotMood.happy);
    _joyTimer?.cancel();
    _joyTimer = Timer(_joyHold, () {
      if (mounted) setState(() => _mood = AssistantMascotMood.idle);
    });
  }

  // Opening the chat is navigation: no haptic (§3.1).
  void _open() {
    _rejoice();
    widget.onOpen();
  }

  void _onThinking((AssistantThought, AssistantBuddyThoughtPhase)? thinking) {
    setState(() {
      _thinking = thinking;
      switch (thinking) {
        case (final thought, AssistantBuddyThoughtPhase.speaking)
            when thought.waves:
          _waves++;
        case (final thought, AssistantBuddyThoughtPhase.said)
            when thought.winks:
          _winks++;
        case _:
          break;
      }
    });
  }

  void _openThought(AssistantThought thought) {
    _rejoice();
    widget.onThoughtTap(thought);
  }

  Future<void> _hide() async {
    Haptics.pick();
    setState(() => _mood = AssistantMascotMood.curious);
    await widget.onHide();
    if (mounted) setState(() => _mood = AssistantMascotMood.idle);
  }

  Offset _restingSpot(Size area, TextDirection direction) {
    final onRight = _atEnd == (direction == TextDirection.ltr);
    return Offset(
      onRight ? area.width - _box - _edge : _edge,
      area.height - _bottom - _box,
    );
  }

  void _dragStart(Offset topLeft) {
    _snap.stop();
    Haptics.pick();
    _drag.value = topLeft;
    setState(() {
      _pressed = false;
      _mood = AssistantMascotMood.surprised;
    });
  }

  void _dragUpdate(DragUpdateDetails details) {
    final drag = _drag.value;
    if (drag != null) _drag.value = drag + details.delta;
  }

  /// Settles on the nearest side (or the side it was flung to), kept
  /// between the bottom bar and the header, on the calm spring.
  void _dragEnd(DragEndDetails details, Size area, TextDirection direction) {
    final from = _drag.value;
    if (from == null) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final onRight = vx.abs() > _flingSpeed
        ? vx > 0
        : from.dx + _box / 2 > area.width / 2;
    final maxBottom = area.height - _box - _topRoom;
    _atEnd = onRight == (direction == TextDirection.ltr);
    _bottom = (area.height - from.dy - _box).clamp(
      _minBottom,
      maxBottom < _minBottom ? _minBottom : maxBottom,
    );
    _snapFrom = from;
    _snapTo = _restingSpot(area, direction);
    setState(() => _mood = AssistantMascotMood.idle);
    if (_reduced) {
      _land();
      return;
    }
    _snap.forward(from: 0).whenComplete(_land);
  }

  // Landing is a reaction, not a gesture: no haptic, a hop when allowed.
  void _land() {
    if (!mounted) return;
    setState(() => _drag.value = null);
    _requestHop();
  }

  @override
  void dispose() {
    widget.touches.removeListener(_onTouch);
    FlyToCart.inFlight.removeListener(_onFlight);
    ConfettiBurst.playing.removeListener(_onFlight);
    _lookBack?.cancel();
    _lookRest?.cancel();
    _hopRest?.cancel();
    _idleTimer?.cancel();
    _joyTimer?.cancel();
    _presenceCurve.dispose();
    _presence.dispose();
    _settle.dispose();
    _snap.dispose();
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final towardsEdge = _atEnd ? 1.0 : -1.0;
    final outward = direction == TextDirection.ltr ? towardsEdge : -towardsEdge;
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        final rest = _restingSpot(area, direction);
        final onRight = rest.dx + _box / 2 > area.width / 2;
        return Stack(
          children: [
            // Built with the layout, not per frame: the bubble sits over
            // the resting spot (a picked-up mascot has none).
            Positioned(
              bottom: area.height - rest.dy + _thoughtGap,
              left: onRight ? null : rest.dx,
              right: onRight ? area.width - rest.dx - _box : null,
              child: ValueListenableBuilder<Offset?>(
                valueListenable: _drag,
                builder: (context, drag, _) => AssistantBuddyThoughtBubble(
                  thought: widget.shown && drag == null ? widget.thought : null,
                  towardsRight: onRight,
                  pressed: _pressed,
                  onPhase: _onThinking,
                  onSaid: widget.onThoughtSaid,
                  onDone: widget.onThoughtDone,
                  onTap: _openThought,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              // The translation is outermost: a transform is hit-tested by
              // where it draws, not by the untranslated box.
              child: AnimatedBuilder(
                animation: Listenable.merge([_presenceCurve, _snap, _drag]),
                builder: (context, child) {
                  final shown = _reduced ? 1.0 : _presenceCurve.value;
                  final drag = _drag.value;
                  final spot = drag == null
                      ? rest
                      : _snap.isAnimating
                      ? Offset.lerp(_snapFrom, _snapTo, _settle.value)!
                      : drag;
                  return Transform.translate(
                    offset: Offset(
                      spot.dx + outward * (1 - shown) * (_box + _edge * 2),
                      spot.dy,
                    ),
                    child: FadeTransition(
                      opacity: _reduced ? _presence : _opaque,
                      child: Visibility(
                        visible: _presence.value > 0,
                        maintainState: true,
                        child: IgnorePointer(
                          ignoring: !widget.shown,
                          child: Transform.scale(
                            scale: _hiddenScale + (1 - _hiddenScale) * shown,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Semantics(
                  button: true,
                  label: 'assistant.entry'.tr(),
                  onTap: _open,
                  customSemanticsActions: {
                    CustomSemanticsAction(label: 'assistant.buddy_hide'.tr()):
                        _hide,
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: _open,
                    onLongPress: _hide,
                    onPanStart: (_) => _dragStart(_drag.value ?? rest),
                    onPanUpdate: _dragUpdate,
                    onPanEnd: (details) => _dragEnd(details, area, direction),
                    child: AnimatedScale(
                      scale: _pressed ? AppMotion.pressedScaleSmall : 1,
                      duration: MotionGuard.duration(
                        context,
                        _pressed ? AppMotion.microPop : AppMotion.fast,
                      ),
                      curve: AppMotion.signature,
                      child: AssistantMascot(
                        key: _mascotKey,
                        size: _box,
                        outlined: true,
                        mood: switch (_thinking) {
                          (final thought, final phase) => thought.moodWhen(
                            phase,
                          ),
                          null => _mood,
                        },
                        look: switch (_thinking) {
                          (final thought, final phase) => thought.lookWhen(
                            phase,
                          ),
                          null => _look,
                        },
                        wake: _wakes,
                        cheer: _hops,
                        wave: _waves,
                        wink: _winks,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
