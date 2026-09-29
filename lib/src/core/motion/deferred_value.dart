import 'dart:async';

import 'package:flutter/widgets.dart';

import 'motion.dart';

/// SEQUENCE a state change (docs/motion D17 extended to state changes,
/// backlog B2-03): hands [builder] the [value] it is given, but a CHANGE of
/// it lands only [delay] later. Blocks of one screen that change on the
/// same frame (a cancel: the headline, the journey bar, the notice, the
/// button) each wait their turn, so they move one after another instead of
/// all at once. `MotionBeat` names the usual delays.
///
/// The first value shows at once; a newer change restarts the wait with the
/// newest value, and a change back to the value on screen cancels it.
/// [deferWhen] limits which changes wait (from the value on screen to the
/// new one): the others land at once and drop a pending one — e.g. a total
/// that must never show a stale amount goes to "Updating…" at once and only
/// its settled amount waits its beat.
/// Reduced motion (or a zero [delay]) → no wait. Only a timer — no frames
/// while waiting.
class DeferredValue<T> extends StatefulWidget {
  const DeferredValue({
    super.key,
    required this.value,
    required this.delay,
    required this.builder,
    this.deferWhen,
  });

  final T value;
  final Duration delay;
  final Widget Function(BuildContext context, T value) builder;

  /// Whether a change from the value on screen to the new one waits
  /// ([delay]); `null` = every change waits.
  final bool Function(T shown, T next)? deferWhen;

  @override
  State<DeferredValue<T>> createState() => _DeferredValueState<T>();
}

class _DeferredValueState<T> extends State<DeferredValue<T>> {
  late T _shown = widget.value;
  Timer? _timer;

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didUpdateWidget(DeferredValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value;
    if (value == _shown) {
      _cancel();
      return;
    }
    final waits = widget.deferWhen?.call(_shown, value) ?? true;
    if (!waits ||
        widget.delay <= Duration.zero ||
        MotionGuard.reduced(context)) {
      _cancel();
      _shown = value;
      return;
    }
    _cancel();
    _timer = Timer(widget.delay, () {
      _timer = null;
      if (mounted) setState(() => _shown = widget.value);
    });
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _shown);
}
