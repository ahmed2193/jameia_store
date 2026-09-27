import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../motion/second_clock.dart';
import '../utils/relative_age.dart';
import 'info_pill.dart';

/// The small "Updated 12 minutes ago" pill over data that did not come from
/// the server just now ([StaleDataNotice] decides when a screen shows it).
/// It fades in once when it appears and re-reads the age once a minute —
/// aligned to the minute, only while its page is on stage — rebuilding only
/// itself.
class StaleAgePill extends StatefulWidget {
  const StaleAgePill({super.key, required this.savedAt, this.clock});

  /// When the data on screen was fetched.
  final DateTime savedAt;

  /// What time it is (tests pin it).
  final DateTime Function()? clock;

  static const Duration _period = Duration(minutes: 1);

  @override
  State<StaleAgePill> createState() => _StaleAgePillState();
}

class _StaleAgePillState extends State<StaleAgePill> {
  late final SecondClock _clock = SecondClock(
    clock: widget.clock,
    period: StaleAgePill._period,
  );

  @override
  void initState() {
    super.initState();
    _clock.addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clock.enabled = TickerMode.valuesOf(context).enabled;
  }

  @override
  void dispose() {
    _clock
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final now = (widget.clock ?? DateTime.now)();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.standard,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: Center(
        child: InfoPill(
          icon: Icons.schedule_rounded,
          text: RelativeAge.updated(widget.savedAt, now: now),
        ),
      ),
    );
  }
}
