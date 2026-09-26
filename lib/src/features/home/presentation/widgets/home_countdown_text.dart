import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/motion/motion_widgets.dart';
import 'home_reveal_scope.dart';

/// `HH:MM:SS` left until [endsAt], ticking once a second like a flip clock:
/// only the part that changed rolls to its new value. Only this text
/// rebuilds on a tick, and not at all while its block is off screen;
/// [onFinished] fires once when the time is up.
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

class _HomeCountdownTextState extends State<HomeCountdownText> {
  static const Duration _tick = Duration(seconds: 1);
  static const int _pad = 2;
  static const String _separator = ':';

  Timer? _timer;
  late Duration _left;
  bool _onScreen = true;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onScreen = HomeRevealScope.onScreenOf(context);
    // Back on screen: show the time as it is now.
    if (_onScreen) _left = _remaining();
  }

  @override
  void didUpdateWidget(covariant HomeCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) _left = _remaining();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _remaining() {
    final left = widget.endsAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _onTick() {
    final left = _remaining();
    if (left == Duration.zero) {
      _timer?.cancel();
      widget.onFinished?.call();
    } else if (!_onScreen) {
      return;
    }
    if (mounted) setState(() => _left = left);
  }

  @override
  Widget build(BuildContext context) {
    String two(int value) => value.toString().padLeft(_pad, '0');
    final parts = [
      _left.inHours,
      _left.inMinutes.remainder(Duration.minutesPerHour),
      _left.inSeconds.remainder(Duration.secondsPerMinute),
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
