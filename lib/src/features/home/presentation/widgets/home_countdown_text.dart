import 'dart:async';

import 'package:flutter/material.dart';

/// `HH:MM:SS` left until [endsAt], ticking once a second. Only this text
/// rebuilds on a tick; [onFinished] fires once when the time is up.
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

  Timer? _timer;
  late Duration _left;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    _timer = Timer.periodic(_tick, (_) => _onTick());
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
    }
    if (mounted) setState(() => _left = left);
  }

  @override
  Widget build(BuildContext context) {
    String two(int value) => value.toString().padLeft(_pad, '0');
    final hours = _left.inHours;
    final minutes = _left.inMinutes.remainder(Duration.minutesPerHour);
    final seconds = _left.inSeconds.remainder(Duration.secondsPerMinute);
    return Text(
      '${two(hours)}:${two(minutes)}:${two(seconds)}',
      style: widget.style,
    );
  }
}
