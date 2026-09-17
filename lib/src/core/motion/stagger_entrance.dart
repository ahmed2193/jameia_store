import 'package:flutter/material.dart';

import 'motion.dart';

/// Staggered list/grid ENTRANCE — each item fades + slides up by a small
/// [beginOffset], delayed by `index * stagger` so a freshly built feed/grid
/// cascades in (Jameia home-feed / coupon-list / search-result reveal). Plays
/// once per element (guarded). Index delay is clamped by [maxIndex] so long
/// lists aren't held back. Reduced-motion → render immediately, no delay.
///
/// Default 30ms step is grounded: Jameia's `home_page_main` staggered dropdown
/// reveal uses per-item delays of 0/30/60ms (docs/jameia_motion_reference.md §2).
class StaggerEntrance extends StatefulWidget {
  const StaggerEntrance({
    super.key,
    required this.index,
    required this.child,
    this.stagger = const Duration(milliseconds: 30),
    this.beginOffset = const Offset(0, 0.08),
    this.maxIndex = 10,
  });

  final int index;
  final Widget child;
  final Duration stagger;
  final Offset beginOffset;
  final int maxIndex;

  @override
  State<StaggerEntrance> createState() => _StaggerEntranceState();
}

class _StaggerEntranceState extends State<StaggerEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return;
    _played = true;
    if (MotionGuard.reduced(context)) {
      _c.value = 1;
      return;
    }
    final steps = widget.index.clamp(0, widget.maxIndex);
    Future<void>.delayed(widget.stagger * steps, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.signature);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
