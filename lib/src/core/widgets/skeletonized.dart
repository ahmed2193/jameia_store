import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../motion/motion.dart';
import '../../config/theme/app_colors.dart';

/// Shimmer SKELETON wrapper. Feed a static stand-in layout that mirrors the
/// real content; while [loading] is true it renders bones. They stand still
/// for the first [AppMotion.loaderDelay] — a read that answers that fast
/// shows plain bones, never a flash of shimmer — then Hero's shimmer sweeps
/// ([AppMotion.shimmer], ~1.1 s; the band enters from off the start edge, so
/// a quick load barely sees it). Reduced motion → solid, still bones. The
/// skeleton repaints behind its own [RepaintBoundary], never the whole page
/// (docs/motion §9.4 #6).
class Skeletonized extends StatefulWidget {
  const Skeletonized({super.key, required this.loading, required this.child});

  final bool loading;
  final Widget child;

  @override
  State<Skeletonized> createState() => _SkeletonizedState();
}

class _SkeletonizedState extends State<Skeletonized> {
  /// The wait is over: the bones may shimmer.
  bool _shimmer = false;
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    if (widget.loading) _startWait();
  }

  @override
  void didUpdateWidget(Skeletonized oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading && !oldWidget.loading) {
      _shimmer = false;
      _startWait();
    } else if (!widget.loading) {
      _wait?.cancel();
    }
  }

  void _startWait() {
    _wait?.cancel();
    _wait = Timer(AppMotion.loaderDelay, () {
      if (mounted) setState(() => _shimmer = true);
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = !_shimmer || MotionGuard.reduced(context);
    return RepaintBoundary(
      child: Skeletonizer(
        enabled: widget.loading,
        effect: still
            ? SolidColorEffect(color: AppColors.divider)
            : ShimmerEffect(
                baseColor: AppColors.divider,
                highlightColor: AppColors.smallBackground,
                duration: AppMotion.shimmer,
              ),
        child: widget.child,
      ),
    );
  }
}
