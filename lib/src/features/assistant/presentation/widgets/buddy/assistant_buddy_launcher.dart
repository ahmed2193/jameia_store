import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_thought.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_buddy_thought_bubble.dart';
import 'assistant_buddy_thought_face.dart';
import 'assistant_buddy_thought_phase.dart';

/// The floating mascot that opens the chat: tap to chat, drag it anywhere
/// (it springs to the nearest side), hold it to hide it for today. It looks
/// towards where the customer touches, hops when [cheers] ticks, and steps
/// off its edge while not [shown] (scrolling down, the greeting on screen).
/// Now and then it thinks out loud ([thought]) in a small bubble over its
/// head — looking up while it thinks, talking while the line types, then
/// reacting to what it said (a smile, a tilted head, a hop for the cheeriest
/// lines). Pressing the mascot squishes the bubble too; a tap on the line
/// opens the chat ([onThoughtTap]).
///
/// Rests at the end side above the home's back-to-top button, so the two
/// never cover each other.
class AssistantBuddyLauncher extends StatefulWidget {
  const AssistantBuddyLauncher({
    super.key,
    required this.shown,
    required this.cheers,
    this.thought,
    required this.onThoughtSaid,
    required this.onThoughtDone,
    required this.alive,
    required this.touches,
    required this.onOpen,
    required this.onThoughtTap,
    required this.onHide,
  });

  final bool shown;
  final int cheers;

  /// The line it is thinking out loud, `null` when none.
  final AssistantThought? thought;
  final ValueChanged<AssistantThought> onThoughtSaid;
  final ValueChanged<AssistantThought> onThoughtDone;

  /// The app is in the foreground: the mascot may blink and glance.
  final bool alive;

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
  static const double _pressedScale = 0.9;
  static const double _hiddenScale = 0.6;
  static const double _flingSpeed = 600;
  static const double _lookReach = 160;
  static const Duration _lookHold = Duration(milliseconds: 1100);
  static const Duration _joyHold = Duration(milliseconds: 900);
  static const double _thoughtGap = AppSpacing.s2;

  /// No touch for this long: the mascot stops blinking and glancing, so a
  /// resting screen draws nothing.
  static const Duration _dozeAfter = Duration(seconds: 30);
  static final SpringDescription _snapSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 0.72);

  final GlobalKey _mascotKey = GlobalKey();

  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: AppMotion.page,
    reverseDuration: AppMotion.medium,
    value: widget.shown ? 1 : 0,
  );
  late final CurvedAnimation _presenceCurve = CurvedAnimation(
    parent: _presence,
    curve: AppMotion.emphasizedDecelerate,
    reverseCurve: AppMotion.exit,
  );
  late final AnimationController _snap = AnimationController.unbounded(
    vsync: this,
  );

  /// Resting spot: which side (reading direction) and how high.
  bool _atEnd = true;
  double _bottom = _restBottom;

  /// Top-left while dragged or springing to its spot; `null` at rest.
  Offset? _drag;
  Offset _snapFrom = Offset.zero;
  Offset _snapTo = Offset.zero;

  bool _pressed = false;
  AssistantMascotMood _mood = AssistantMascotMood.idle;
  Offset _look = Offset.zero;
  (AssistantThought, AssistantBuddyThoughtPhase)? _thinking;
  int _landings = 0;

  /// Gestures for what it says: a hop for the cheeriest lines once said, a
  /// wave of the sprout as it greets, a wink as company.
  int _joys = 0;
  int _waves = 0;
  int _winks = 0;
  bool _dozing = false;
  Timer? _lookTimer;
  Timer? _joyTimer;
  Timer? _dozeTimer;

  @override
  void initState() {
    super.initState();
    widget.touches.addListener(_glanceAtTouch);
    _wake();
  }

  @override
  void didUpdateWidget(AssistantBuddyLauncher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.touches != widget.touches) {
      oldWidget.touches.removeListener(_glanceAtTouch);
      widget.touches.addListener(_glanceAtTouch);
    }
    if (oldWidget.shown != widget.shown) {
      if (MotionGuard.reduced(context)) {
        _presence.value = widget.shown ? 1 : 0;
      } else {
        widget.shown ? _presence.forward() : _presence.reverse();
      }
    }
  }

  void _wake() {
    _dozeTimer?.cancel();
    if (_dozing) setState(() => _dozing = false);
    _dozeTimer = Timer(_dozeAfter, () {
      if (mounted) setState(() => _dozing = true);
    });
  }

  /// Eyes follow the customer's taps for a moment.
  void _glanceAtTouch() {
    _wake();
    final touch = widget.touches.value;
    final box = _mascotKey.currentContext?.findRenderObject();
    if (touch == null || !widget.shown || _drag != null || box is! RenderBox) {
      return;
    }
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final delta = touch - center;
    if (delta.distance < _box) return; // a tap on the mascot itself
    final reach = (delta.distance / _lookReach).clamp(0.0, 1.0);
    setState(() => _look = delta / delta.distance * reach);
    _lookTimer?.cancel();
    _lookTimer = Timer(_lookHold, () {
      if (mounted) setState(() => _look = Offset.zero);
    });
  }

  void _rejoice() {
    setState(() => _mood = AssistantMascotMood.happy);
    _joyTimer?.cancel();
    _joyTimer = Timer(_joyHold, () {
      if (mounted) setState(() => _mood = AssistantMascotMood.idle);
    });
  }

  void _open() {
    Haptics.tap();
    _rejoice();
    widget.onOpen();
  }

  void _onThinking((AssistantThought, AssistantBuddyThoughtPhase)? thinking) {
    setState(() {
      _thinking = thinking;
      switch (thinking) {
        case (final thought, AssistantBuddyThoughtPhase.typing)
            when thought.waves:
          _waves++;
        case (final thought, AssistantBuddyThoughtPhase.said):
          if (thought.playful) _joys++;
          if (thought.winks) _winks++;
        case _:
          break;
      }
    });
  }

  void _openThought(AssistantThought thought) {
    Haptics.tap();
    _rejoice();
    widget.onThoughtTap(thought);
  }

  Future<void> _hide() async {
    Haptics.selection();
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
    Haptics.selection();
    setState(() {
      _pressed = false;
      _drag = topLeft;
      _mood = AssistantMascotMood.surprised;
    });
  }

  void _dragUpdate(DragUpdateDetails details) {
    final drag = _drag;
    if (drag != null) setState(() => _drag = drag + details.delta);
  }

  /// Springs to the nearest side (or the side it was flung to), kept
  /// between the bottom bar and the header.
  void _dragEnd(DragEndDetails details, Size area, TextDirection direction) {
    final from = _drag;
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
    if (MotionGuard.reduced(context)) {
      _land();
      return;
    }
    _snap
      ..value = 0
      ..animateWith(SpringSimulation(_snapSpring, 0, 1, 0)).whenComplete(_land);
  }

  void _land() {
    if (!mounted) return;
    Haptics.tap();
    setState(() {
      _drag = null;
      _landings++;
    });
  }

  @override
  void dispose() {
    widget.touches.removeListener(_glanceAtTouch);
    _lookTimer?.cancel();
    _joyTimer?.cancel();
    _dozeTimer?.cancel();
    _presenceCurve.dispose();
    _presence.dispose();
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final towardsEdge = _atEnd ? 1.0 : -1.0;
    final outward = direction == TextDirection.ltr ? towardsEdge : -towardsEdge;
    // Picked up or away: whatever it was thinking goes.
    final thought = widget.shown && _drag == null ? widget.thought : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        return AnimatedBuilder(
          animation: Listenable.merge([_presenceCurve, _snap]),
          builder: (context, child) {
            final shown = _presenceCurve.value;
            final spot = _drag == null
                ? _restingSpot(area, direction)
                : _snap.isAnimating
                ? Offset.lerp(_snapFrom, _snapTo, _snap.value)!
                : _drag!;
            final onRight = spot.dx + _box / 2 > area.width / 2;
            return Stack(
              children: [
                Positioned(
                  bottom: area.height - spot.dy + _thoughtGap,
                  left: onRight ? null : spot.dx,
                  right: onRight ? area.width - spot.dx - _box : null,
                  child: AssistantBuddyThoughtBubble(
                    thought: thought,
                    towardsRight: onRight,
                    pressed: _pressed,
                    onPhase: _onThinking,
                    onSaid: widget.onThoughtSaid,
                    onDone: widget.onThoughtDone,
                    onTap: _openThought,
                  ),
                ),
                Positioned(
                  left: spot.dx + outward * (1 - shown) * (_box + _edge * 2),
                  top: spot.dy,
                  child: Visibility(
                    visible: shown > 0,
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
              ],
            );
          },
          child: Semantics(
            button: true,
            label: 'assistant.entry'.tr(),
            onTap: _open,
            customSemanticsActions: {
              CustomSemanticsAction(label: 'assistant.buddy_hide'.tr()): _hide,
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: _open,
              onLongPress: _hide,
              onPanStart: (_) =>
                  _dragStart(_drag ?? _restingSpot(area, direction)),
              onPanUpdate: _dragUpdate,
              onPanEnd: (details) => _dragEnd(details, area, direction),
              child: AnimatedScale(
                scale: _pressed ? _pressedScale : 1,
                duration: MotionGuard.duration(context, AppMotion.fast),
                curve: AppMotion.signature,
                child: AssistantMascot(
                  key: _mascotKey,
                  size: _box,
                  outlined: true,
                  mood: switch (_thinking) {
                    (final thought, final phase) => thought.moodWhen(phase),
                    null => _mood,
                  },
                  look: switch (_thinking) {
                    (final thought, final phase) => thought.lookWhen(phase),
                    null => _look,
                  },
                  alive: widget.alive && widget.shown && !_dozing,
                  cheer: (widget.cheers, _landings, _joys),
                  wave: _waves,
                  wink: _winks,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
