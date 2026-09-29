import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// A star's face: the grey outline, with the filled star (brand, pressed
/// shade) scaled over it. Filling pops the star in with the snappy spring
/// after `delaySteps × AppMotion.staggerStep` (the multi-star cascade — one
/// controller, the delay is an [Interval], no timer); emptying shrinks it
/// out quickly. Static on mount; reduced motion → the end state at once.
class ReviewStarIcon extends StatefulWidget {
  const ReviewStarIcon({super.key, required this.filled, this.delaySteps = 0});

  final bool filled;

  /// How many stars pop before this one in the same fill.
  final int delaySteps;

  @override
  State<ReviewStarIcon> createState() => _ReviewStarIconState();
}

class _ReviewStarIconState extends State<ReviewStarIcon>
    with SingleTickerProviderStateMixin {
  static const double _shown = 1;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.filled ? _shown : 0,
  );
  late Animation<double> _scale = _controller.view;

  @override
  void didUpdateWidget(ReviewStarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filled == widget.filled) return;
    if (MotionGuard.reduced(context)) {
      _scale = _controller.view;
      _controller.value = widget.filled ? _shown : 0;
      return;
    }
    if (widget.filled) {
      final delay = AppMotion.staggerStep * widget.delaySteps;
      final total = delay + AppSprings.snappy.duration;
      _scale = _controller.drive(
        CurveTween(
          curve: Interval(
            delay.inMicroseconds / total.inMicroseconds,
            _shown,
            curve: AppSprings.snappy,
          ),
        ),
      );
      _controller
        ..duration = total
        ..forward(from: 0);
    } else {
      _scale = _controller.drive(CurveTween(curve: AppMotion.exit));
      _controller
        ..duration = AppMotion.fast
        ..reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.star_border_rounded,
          size: AppSize.s28,
          color: AppColors.secondaryText,
        ),
        // At scale 0 nothing is painted (a degenerate transform is skipped).
        ScaleTransition(
          scale: _scale,
          child: const Icon(
            Icons.star_rounded,
            size: AppSize.s28,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
