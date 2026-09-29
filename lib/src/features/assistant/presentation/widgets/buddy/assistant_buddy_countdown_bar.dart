import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// A hairline that runs down while the greeting waits ([elapsed] `0..1`),
/// so its leaving is never a surprise. Scaled, not re-laid out, each frame.
/// Reduced motion: the bar holds still, full (the time still runs).
class AssistantBuddyCountdownBar extends StatelessWidget {
  const AssistantBuddyCountdownBar({super.key, required this.elapsed});

  final Animation<double> elapsed;

  /// Below this share of the time left, the fill is simply gone.
  static const double _minLeft = 0.01;

  static const BorderRadius _round = BorderRadius.all(
    Radius.circular(AppSize.r2),
  );
  static const BoxDecoration _track = BoxDecoration(
    color: AppColors.brandLightBg,
    borderRadius: _round,
  );
  static const BoxDecoration _fill = BoxDecoration(
    color: AppColors.primary,
    borderRadius: _round,
  );

  @override
  Widget build(BuildContext context) {
    final still = MotionGuard.reduced(context);
    final origin = AlignmentDirectional.centerStart.resolve(
      Directionality.of(context),
    );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: AppSize.s3,
          width: double.infinity,
          child: DecoratedBox(
            decoration: _track,
            child: AnimatedBuilder(
              animation: still ? kAlwaysCompleteAnimation : elapsed,
              // Never scaled to zero: a degenerate transform crashes some
              // GPU back ends (seen with Impeller on the emulator).
              builder: (context, child) {
                final left = still ? 1.0 : 1 - elapsed.value;
                return left < _minLeft
                    ? const SizedBox.shrink()
                    : Transform(
                        alignment: origin,
                        transform: Matrix4.diagonal3Values(left, 1, 1),
                        child: child,
                      );
              },
              child: const DecoratedBox(decoration: _fill),
            ),
          ),
        ),
      ),
    );
  }
}
