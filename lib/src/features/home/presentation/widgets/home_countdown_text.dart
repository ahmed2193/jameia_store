import 'package:flutter/material.dart';

import '../../../../core/motion/motion_widgets.dart';

/// `HH:MM:SS` left until [endsAt], ticking once a second like a flip clock:
/// only the part that changed rolls to its new value. It ticks on the nearest
/// `SecondClockScope`'s clock (else on one [SecondClock] of its own), and it
/// lets go of the clock while it is off screen ([OnScreenGate]), the app is
/// in the background or the tab is hidden —
/// no timer runs for a countdown nobody sees (docs/motion PB-06). Back on
/// screen it shows the time as it is now. [onFinished] fires once when the
/// time is up. The clock half is shared with `CountdownDigits`
/// ([SecondClockFollower]).
class HomeCountdownText extends StatefulWidget {
  const HomeCountdownText({
    super.key,
    required this.endsAt,
    required this.style,
    this.onFinished,
  });

  final DateTime endsAt;
  final TextStyle style;
  final VoidCallback? onFinished;

  @override
  State<HomeCountdownText> createState() => _HomeCountdownTextState();
}

class _HomeCountdownTextState extends State<HomeCountdownText>
    with
        OnScreenGate<HomeCountdownText>,
        SecondClockFollower<HomeCountdownText> {
  static const int _pad = 2;
  static const String _separator = ':';

  /// Only without a scope: this text's own clock.
  SecondClock? _own;
  bool _tickersOn = true;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (followedClock == null) {
      followClock(SecondClockScope.maybeOf(context) ?? (_own = SecondClock()));
    }
    // A scope rests its clock by itself; an own clock follows the tab.
    _tickersOn = TickerMode.valuesOf(context).enabled;
    _own?.enabled = _tickersOn;
    _sync();
  }

  /// Back on screen it shows the time as it is now.
  @override
  void onScreenChanged() => setState(_sync);

  bool get _live => onScreen && _tickersOn;

  @override
  void didUpdateWidget(covariant HomeCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt == widget.endsAt) return;
    _finished = false;
    _sync();
  }

  @override
  void dispose() {
    // Let go before the own clock goes.
    stopListeningToClock();
    _own?.dispose();
    super.dispose();
  }

  Duration get _left => timeLeftUntil(widget.endsAt);

  /// Listens while on screen and running; at zero, finishes after the frame.
  void _sync() {
    if (_left == Duration.zero) {
      stopListeningToClock();
      if (!_finished) {
        _finished = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFinished?.call();
        });
      }
      return;
    }
    listenToClock(_live);
  }

  @override
  void onClockTick() {
    if (!mounted) return;
    if (_left == Duration.zero && !_finished) {
      _finished = true;
      stopListeningToClock();
      widget.onFinished?.call();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    String two(int value) => value.toString().padLeft(_pad, '0');
    final parts = [
      left.inHours,
      left.inMinutes.remainder(Duration.minutesPerHour),
      left.inSeconds.remainder(Duration.secondsPerMinute),
    ];
    return Semantics(
      label: parts.map(two).join(_separator),
      excludeSemantics: true,
      // A clock reads left to right in either language.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, value) in parts.indexed) ...[
              if (index > 0) Text(_separator, style: widget.style),
              FlipValue(
                flipKey: value,
                child: Text(two(value), style: widget.style),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
