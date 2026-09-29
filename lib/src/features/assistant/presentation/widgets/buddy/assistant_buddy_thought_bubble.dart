import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/assistant_thought.dart';
import '../assistant_motion.dart';
import 'assistant_buddy_thought_cloud.dart';
import 'assistant_buddy_thought_line.dart';
import 'assistant_buddy_thought_phase.dart';
import 'assistant_buddy_thought_trail.dart';

/// What the launcher's mascot thinks out loud, in a thought bubble over its
/// head (docs/motion §9.6 §3.1 row 9). The thought rises out of the mascot
/// over [AppMotion.slow] — the small circle, the big one, then the bubble,
/// each on the snappy spring — and its words start at once, word by word
/// (no dots: nothing real is being worked out). Then a moment to read it
/// (`thoughtReadBase` + `thoughtReadPerLetter`), [onSaid]; a new [thought]
/// arriving then takes over in place, otherwise the bubble sinks back into
/// the mascot over [AppMotion.medium] / `exit` ([onDone]). A line sent away
/// before it was out (the customer acted) sinks in [AppMotion.fast]. It
/// holds still while it is up: no bob, no rocking badge.
///
/// [onPhase] lets the mascot react along. The bubble dips while the mascot
/// is [pressed] and when it is tapped itself ([onTap], the chat). Screen
/// readers hear each line once. Off stage (its tab hidden, a page on top)
/// it goes at once and its timer with it. Reduced motion: the line fades in
/// whole over [AppMotion.fast], stays as long, and fades out.
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
  // Out of the mascot: the small circle over its head, the big one, then
  // the bubble — and back down the other way.
  static const double _smallUntil = 0.45;
  static const double _bigFrom = 0.15;
  static const double _bigUntil = 0.65;
  static const double _cloudFrom = 0.3;
  static const Animation<double> _whole = AlwaysStoppedAnimation<double>(1);

  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    reverseDuration: AppMotion.medium,
  );
  late final CurvedAnimation _small = _stage(0, _smallUntil);
  late final CurvedAnimation _big = _stage(_bigFrom, _bigUntil);
  late final CurvedAnimation _cloud = _stage(_cloudFrom, 1);

  /// The thought on screen — kept through its exit.
  AssistantThought? _shown;
  AssistantBuddyThoughtPhase? _phase;
  bool _leaving = false;
  bool _ready = false;
  bool _reduced = false;
  Timer? _read;

  CurvedAnimation _stage(double from, double until) => CurvedAnimation(
    parent: _presence,
    curve: Interval(from, until, curve: AppSprings.snappy),
    reverseCurve: Interval(from, until, curve: AppMotion.exit),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionGuard.reduced(context);
    final onStage = TickerMode.valuesOf(context).enabled;
    if (!_ready) {
      _ready = true;
      final thought = widget.thought;
      if (thought != null && onStage) _begin(thought);
      return;
    }
    if (!onStage) _dropOffStage();
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
    _read?.cancel();
    // A line still up hands over in place; otherwise the bubble rises.
    final handOver = _shown != null && !_leaving;
    _shown = thought;
    _leaving = false;
    _phase = AssistantBuddyThoughtPhase.speaking;
    _report();
    if (handOver) return;
    if (_reduced) {
      _presence.animateTo(1, duration: AppMotion.fast);
    } else {
      _presence.forward(from: _presence.value);
    }
  }

  /// Every word is in: a moment to read it.
  void _onRevealed(AssistantThought thought) {
    if (_shown != thought ||
        _leaving ||
        _phase != AssistantBuddyThoughtPhase.speaking) {
      return;
    }
    setState(() => _phase = AssistantBuddyThoughtPhase.said);
    _report();
    _read = Timer(_readTime(thought), () => _said(thought));
  }

  Duration _readTime(AssistantThought thought) =>
      AssistantMotion.thoughtReadBase +
      AssistantMotion.thoughtReadPerLetter *
          thought.textKey.tr().characters.length;

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
    _read?.cancel();
    final leaving = _shown;
    if (leaving == null || _leaving) return;
    // Sent away before it was out (the customer acted): a quick exit.
    final cut = _phase != AssistantBuddyThoughtPhase.said;
    _leaving = true;
    _report();
    final TickerFuture gone = _reduced || cut
        ? _presence.animateBack(0, duration: AppMotion.fast)
        : _presence.reverse();
    gone.then((_) => _gone(leaving));
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

  /// Its tab went out of view or a page covers it: the line goes now (a
  /// muted ticker would finish it later, out of the blue), timer and all.
  void _dropOffStage() {
    _read?.cancel();
    final shown = _shown;
    if (shown == null) return;
    _presence.value = 0;
    _shown = null;
    _phase = null;
    _leaving = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPhase(null);
      widget.onDone(shown);
    });
  }

  @override
  void dispose() {
    _read?.cancel();
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
    final Widget bubble = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.towardsRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _reduced ? _whole : _cloud,
          alignment: corner,
          child: AssistantBuddyThoughtCloud(
            pressed: widget.pressed,
            alignment: corner,
            onTap: () => widget.onTap(shown),
            child: AssistantBuddyThoughtLine(
              thought: shown,
              alignment: corner,
              onRevealed: _onRevealed,
            ),
          ),
        ),
        AssistantBuddyThoughtTrail(
          towardsRight: widget.towardsRight,
          big: _reduced ? _whole : _big,
          small: _reduced ? _whole : _small,
        ),
      ],
    );
    return Semantics(
      container: true,
      liveRegion: true,
      button: true,
      label: shown.textKey.tr(),
      onTap: () => widget.onTap(shown),
      child: ExcludeSemantics(
        child: _reduced
            ? FadeTransition(opacity: _presence, child: bubble)
            : bubble,
      ),
    );
  }
}
