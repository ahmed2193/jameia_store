import 'dart:async';

import 'package:flutter/material.dart';

import 'motion.dart';

/// Staggered list/grid ENTRANCE — each item fades + slides up by a small
/// [beginOffset], delayed by `index * stagger` so a freshly built feed/grid
/// cascades in (Hero home-feed / coupon-list / search-result reveal). Plays
/// once per element (guarded). Index delay is clamped by [maxIndex] so long
/// lists aren't held back. Reduced-motion → render immediately, no delay.
///
/// Default 30ms step is grounded: Hero's `home_page_main` staggered dropdown
/// reveal uses per-item delays of 0/30/60ms (docs/hero_motion_reference.md §2).
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
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _c,
    curve: AppMotion.signature,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.beginOffset,
    end: Offset.zero,
  ).animate(_curve);

  /// The index delay; cancelled on dispose so no timer outlives the item.
  Timer? _delay;
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
    _delay = Timer(widget.stagger * steps, _c.forward);
  }

  @override
  void dispose() {
    _delay?.cancel();
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
