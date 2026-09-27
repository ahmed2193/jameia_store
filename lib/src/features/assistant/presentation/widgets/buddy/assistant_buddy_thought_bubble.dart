import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../domain/entities/assistant_thought.dart';
import 'assistant_buddy_thought_cloud.dart';
import 'assistant_buddy_thought_face.dart';
import 'assistant_buddy_thought_line.dart';
import 'assistant_buddy_thought_phase.dart';
import 'assistant_buddy_thought_trail.dart';

/// What the launcher's mascot thinks out loud, in a thought bubble over its
/// head. The thought rises out of the mascot — the small circle, the big
/// one, then the bubble — and floats gently while it is up: a few dots
/// while the mascot thinks, the line typing itself out at a natural pace,
/// then a moment to read it ([onSaid]). A new [thought] arriving then takes
/// over in place — the line lifts away, the dots come back, the next one
/// types; otherwise the bubble sinks back into the mascot ([onDone]).
///
/// [onPhase] lets the mascot react along; a playful line ends with a little
/// bump. The bubble squishes while the mascot is [pressed] and when it is
/// tapped itself ([onTap], the chat). Screen readers hear each line once.
/// Reduced motion: lines show whole, stay as long, and go.
class AssistantBuddyThoughtBubble extends StatefulWidget {
  const AssistantBuddyThoughtBubble({
    super.key,
    required this.thought,
    required this.towardsRight,
    required this.pressed,
    required this.onPhase,
    required this.onSaid,
    required this.onDone,
    required this.onTap,
  });

  /// The thought to show; `null` sends the one on screen away.
  final AssistantThought? thought;

  /// The mascot is on the bubble's right (the bubble grows from there).
  final bool towardsRight;
  final bool pressed;
  final ValueChanged<(AssistantThought, AssistantBuddyThoughtPhase)?> onPhase;
  final ValueChanged<AssistantThought> onSaid;
  final ValueChanged<AssistantThought> onDone;
  final ValueChanged<AssistantThought> onTap;

  @override
  State<AssistantBuddyThoughtBubble> createState() =>
      _AssistantBuddyThoughtBubbleState();
}

class _AssistantBuddyThoughtBubbleState
    extends State<AssistantBuddyThoughtBubble>
    with SingleTickerProviderStateMixin {
  static const Duration _thinkFor = Duration(milliseconds: 1100);
  static const Duration _thinkAgainFor = Duration(milliseconds: 700);
  static const Duration _readFor = Duration(milliseconds: 1800);
  static const Duration _readPerLetter = Duration(milliseconds: 35);

  // Out of the mascot: the small circle over its head, the big one, then
  // the bubble — and back down the other way.
  static const double _smallUntil = 0.45;
  static const double _bigFrom = 0.15;
  static const double _bigUntil = 0.65;
  static const double _cloudFrom = 0.3;

  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    reverseDuration: AppMotion.page,
  );
  late final CurvedAnimation _small = _stage(0, _smallUntil);
  late final CurvedAnimation _big = _stage(_bigFrom, _bigUntil);
  late final CurvedAnimation _cloud = _stage(_cloudFrom, 1);

  /// The thought on screen — kept through its exit.
  AssistantThought? _shown;
  AssistantBuddyThoughtPhase? _phase;
  bool _leaving = false;
  bool _ready = false;
  int _bumps = 0;
  Timer? _next;

  CurvedAnimation _stage(double from, double until) => CurvedAnimation(
    parent: _presence,
    curve: Interval(from, until, curve: AppSprings.snappy),
    reverseCurve: Interval(from, until, curve: AppMotion.exit),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final thought = widget.thought;
    if (thought != null) _begin(thought);
  }

  @override
  void didUpdateWidget(AssistantBuddyThoughtBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final thought = widget.thought;
    if (thought == oldWidget.thought) return;
    if (thought == null) {
      _leave();
    } else {
      _begin(thought);
    }
  }

  /// Tells the mascot after this frame (never in the middle of its build).
  void _report() {
    final shown = _shown;
    final phase = _phase;
    final face = shown == null || phase == null || _leaving
        ? null
        : (shown, phase);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPhase(face);
    });
  }

  void _begin(AssistantThought thought) {
    _next?.cancel();
    // A line still up hands over in place; otherwise the bubble rises.
    final handOver = _shown != null && !_leaving;
    _shown = thought;
    _leaving = false;
    if (MotionGuard.reduced(context)) {
      _phase = AssistantBuddyThoughtPhase.said;
      _presence.value = 1;
      _report();
      _next = Timer(_readTime(thought), () => _said(thought));
      return;
    }
    _phase = AssistantBuddyThoughtPhase.thinking;
    _report();
    if (!handOver) _presence.forward(from: _presence.value);
    _next = Timer(handOver ? _thinkAgainFor : _thinkFor, () {
      if (!mounted || _shown != thought) return;
      setState(() => _phase = AssistantBuddyThoughtPhase.typing);
      _report();
    });
  }

  /// Typed out: a moment to read it (a playful line bumps).
  void _onTyped(AssistantThought thought) {
    if (_shown != thought || _phase != AssistantBuddyThoughtPhase.typing) {
      return;
    }
    setState(() {
      _phase = AssistantBuddyThoughtPhase.said;
      if (thought.playful) _bumps++;
    });
    _report();
    _next = Timer(_readTime(thought), () => _said(thought));
  }

  Duration _readTime(AssistantThought thought) =>
      _readFor + _readPerLetter * thought.textKey.tr().characters.length;

  /// Read. The parent may hand over the next line; if it has not by the
  /// next frame, the bubble goes.
  void _said(AssistantThought thought) {
    if (!mounted || _shown != thought || _leaving) return;
    widget.onSaid(thought);
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted && _shown == thought && !_leaving) _leave();
      })
      ..ensureVisualUpdate();
  }

  void _leave() {
    _next?.cancel();
    final leaving = _shown;
    if (leaving == null || _leaving) return;
    _leaving = true;
    _report();
    if (MotionGuard.reduced(context)) {
      _presence.value = 0;
      _gone(leaving);
      return;
    }
    _presence.reverse().then((_) => _gone(leaving));
  }

  void _gone(AssistantThought leaving) {
    if (!mounted || _shown != leaving || !_leaving) return;
    setState(() {
      _shown = null;
      _phase = null;
      _leaving = false;
    });
    widget.onDone(leaving);
  }

  @override
  void dispose() {
    _next?.cancel();
    _small.dispose();
    _big.dispose();
    _cloud.dispose();
    _presence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    final corner = widget.towardsRight
        ? Alignment.bottomRight
        : Alignment.bottomLeft;
    return Semantics(
      container: true,
      liveRegion: true,
      button: true,
      label: shown.textKey.tr(),
      onTap: () => widget.onTap(shown),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.towardsRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ScaleTransition(
              scale: _cloud,
              alignment: corner,
              child: AssistantBuddyThoughtCloud(
                pressed: widget.pressed,
                bumps: _bumps,
                alignment: corner,
                onTap: () => widget.onTap(shown),
                child: AssistantBuddyThoughtLine(
                  thought: shown,
                  thinking: _phase == AssistantBuddyThoughtPhase.thinking,
                  alignment: corner,
                  onTyped: _onTyped,
                ),
              ),
            ),
            AssistantBuddyThoughtTrail(
              towardsRight: widget.towardsRight,
              big: _big,
              small: _small,
            ),
          ],
        ),
      ),
    );
  }
}
