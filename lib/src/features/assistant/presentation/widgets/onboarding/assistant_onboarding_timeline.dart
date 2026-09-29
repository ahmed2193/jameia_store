import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import 'assistant_onboarding_cue.dart';

/// One moment of a tour demo: [AssistantOnboardingCue] for the mascot once
/// the demo's progress passes `at`.
typedef AssistantOnboardingBeat = (double at, AssistantOnboardingCue cue);

/// Plays a tour step's little demo ONCE per opening of the tour (docs/motion
/// §9.6 §2.12): the first time its page becomes [active] it rebuilds
/// [builder] with the demo's progress (`0 → 1` over [length]) and tells
/// [onCue] as the progress passes each of [beats], so the mascot up top
/// reacts to what happens on the stage. A step already [played] shows its
/// end at once and says nothing; a page swiped away mid-demo is never reset
/// under the customer's eyes (it finishes quietly — its cues are for the
/// step in front only). Reduced motion shows the end at once. The stage is
/// its own layer, and nothing loops: a played demo draws no more frames.
class AssistantOnboardingTimeline extends StatefulWidget {
  const AssistantOnboardingTimeline({
    super.key,
    required this.active,
    required this.length,
    required this.builder,
    this.played = false,
    this.beats = const [],
    this.onCue,
    this.onDone,
  });

  final bool active;

  /// This step's demo already played in this opening of the tour.
  final bool played;
  final Duration length;
  final Widget Function(BuildContext context, double progress) builder;
  final List<AssistantOnboardingBeat> beats;
  final ValueChanged<AssistantOnboardingCue>? onCue;

  /// The demo reached its end while it played (at once under reduced
  /// motion); never for a step shown as already played.
  final VoidCallback? onDone;

  @override
  State<AssistantOnboardingTimeline> createState() =>
      _AssistantOnboardingTimelineState();
}

class _AssistantOnboardingTimelineState
    extends State<AssistantOnboardingTimeline>
    with SingleTickerProviderStateMixin {
  /// A breath after the page lands before its demo starts.
  static const Duration _lead = AppMotion.fast;

  late final AnimationController _progress =
      AnimationController(vsync: this, duration: widget.length)
        ..addListener(_onTick)
        ..addStatusListener(_onStatus);

  double _last = 0;
  bool _started = false;
  bool _silent = false;
  Timer? _start;

  @override
  void initState() {
    super.initState();
    if (widget.played) {
      // Seen already: its end, as it was left.
      _started = true;
      _silent = true;
      _progress.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(AssistantOnboardingTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) _progress.duration = widget.length;
    if (oldWidget.active != widget.active) _maybeStart();
  }

  /// The first time the page is in front: plays after a breath (after this
  /// frame, so the beats never rebuild the sheet in the middle of a build).
  void _maybeStart() {
    if (_started || !widget.active) return;
    _started = true;
    final reduced = MotionGuard.reduced(context);
    _start = Timer(reduced ? Duration.zero : _lead, () {
      if (!mounted) return;
      if (reduced) {
        _progress.value = 1;
      } else {
        _progress.forward();
      }
    });
  }

  void _onTick() {
    final now = _progress.value;
    if (now > _last && !_silent && widget.active) {
      for (final (at, cue) in widget.beats) {
        if (_last < at && at <= now) widget.onCue?.call(cue);
      }
    }
    _last = now;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_silent) {
      widget.onDone?.call();
    }
  }

  @override
  void dispose() {
    _start?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _progress,
      builder: (context, _) => widget.builder(context, _progress.value),
    ),
  );
}

/// Where one part of a demo is at the demo's overall progress: `0` before
/// [begin], `1` after [end], eased by [curve] in between (a spring may pass
/// `1` on its way).
extension AssistantOnboardingSpan on double {
  double span(double begin, double end, [Curve curve = AppMotion.signature]) =>
      curve.transform(((this - begin) / (end - begin)).clamp(0.0, 1.0));
}
