import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The blinking bar in the slot the next digit goes to: on for half a
/// second, off for half a second. Its own repaint boundary, so the blink
/// repaints this bar only; it stops off-screen (ticker mode) and is a steady
/// bar under reduced motion.
class OtpSlotCaret extends StatefulWidget {
  const OtpSlotCaret({super.key});

  @override
  State<OtpSlotCaret> createState() => _OtpSlotCaretState();
}

class _OtpSlotCaretState extends State<OtpSlotCaret>
    with SingleTickerProviderStateMixin {
  /// One on + off cycle (500 ms each), like a text cursor.
  static const Duration _period = Duration(milliseconds: 1000);

  /// Starting half-way makes the bar visible right away.
  static const double _visibleFrom = 0.5;

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: _period,
  );
  late final Animation<double> _opacity = _blink.drive(
    CurveTween(curve: const Threshold(_visibleFrom)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionGuard.reduced(context)) {
      _blink
        ..stop()
        ..value = 1;
    } else if (!_blink.isAnimating) {
      _blink
        ..value = _visibleFrom
        ..repeat();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: const SizedBox(
          width: AppSize.s2,
          height: AppSize.s24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(AppSize.r1)),
            ),
          ),
        ),
      ),
    );
  }
}
