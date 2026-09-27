import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import 'assistant_onboarding_cue.dart';

/// One moment of a tour demo: [AssistantOnboardingCue] for the mascot once
/// the demo's progress passes `at`.
typedef AssistantOnboardingBeat = (double at, AssistantOnboardingCue cue);

/// Plays a tour step's little demo each time its page becomes [active]: it
/// rebuilds [builder] with the demo's progress (`0 → 1` over [length]) and
/// tells [onCue] as the progress passes each of [beats], so the mascot up
/// top reacts to what happens on the stage. A page that is not active rests
/// at the start, so coming back plays the demo again; reduced motion shows
/// its end at once. Nothing loops: a played demo draws no more frames.
class AssistantOnboardingTimeline extends StatefulWidget {
  const AssistantOnboardingTimeline({
    super.key,
    required this.active,
    required this.length,
    required this.builder,
    this.beats = const [],
    this.onCue,
    this.onDone,
  });

  final bool active;
  final Duration length;
  final Widget Function(BuildContext context, double progress) builder;
  final List<AssistantOnboardingBeat> beats;
  final ValueChanged<AssistantOnboardingCue>? onCue;

  /// The demo reached its end (at once under reduced motion).
  final VoidCallback? onDone;

  @override
  State<AssistantOnboardingTimeline> createState() =>
      _AssistantOnboardingTimelineState();
}

class _AssistantOnboardingTimelineState
    extends State<AssistantOnboardingTimeline>
    with SingleTickerProviderStateMixin {
  /// A breath after the page lands before its demo starts.
  static const Duration _lead = Duration(milliseconds: 180);

  late final AnimationController _progress =
      AnimationController(vsync: this, duration: widget.length)
        ..addListener(_onTick)
        ..addStatusListener(_onStatus);

  double _last = 0;
  bool? _reduced;
  Timer? _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MotionGuard.reduced(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    _sync();
  }

  @override
  void didUpdateWidget(AssistantOnboardingTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) _progress.duration = widget.length;
    if (oldWidget.active != widget.active) _sync();
  }

  /// Back to the start; an active page plays after this frame, so the
  /// beats never rebuild the sheet in the middle of a build.
  void _sync() {
    _start?.cancel();
    _progress.stop();
    _last = 0;
    _progress.value = 0;
    if (!widget.active) return;
    final reduced = _reduced ?? false;
    _start = Timer(reduced ? Duration.zero : _lead, () {
      if (!mounted || !widget.active) return;
      if (reduced) {
        _progress.value = 1;
      } else {
        _progress.forward();
      }
    });
  }

  void _onTick() {
    final now = _progress.value;
    if (now > _last) {
      for (final (at, cue) in widget.beats) {
        if (_last < at && at <= now) widget.onCue?.call(cue);
      }
    }
    _last = now;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDone?.call();
  }

  @override
  void dispose() {
    _start?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, _) => widget.builder(context, _progress.value),
  );
}

/// Where one part of a demo is at the demo's overall progress: `0` before
/// [begin], `1` after [end], eased by [curve] in between (a spring may pass
/// `1` on its way).
extension AssistantOnboardingSpan on double {
  double span(double begin, double end, [Curve curve = AppMotion.signature]) =>
      curve.transform(((this - begin) / (end - begin)).clamp(0.0, 1.0));
}
