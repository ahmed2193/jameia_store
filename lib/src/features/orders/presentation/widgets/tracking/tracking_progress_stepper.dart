import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// Six dots joined by lines, filled up to the current [step]
/// (placed → confirmed → picking → ready → out for delivery → delivered).
class TrackingProgressStepper extends StatelessWidget {
  const TrackingProgressStepper({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.medium);
    return Row(
      children: [
        for (var i = 0; i < OrderStatus.progressSteps; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: duration,
                curve: AppMotion.standard,
                height: AppSize.s2,
                color: i <= step
                    ? AppColors.primary
                    : AppColors.trackingLineTodo,
              ),
            ),
          AnimatedContainer(
            duration: duration,
            curve: AppMotion.standard,
            width: i == step ? AppSize.s16 : AppSize.s10,
            height: i == step ? AppSize.s16 : AppSize.s10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= step ? AppColors.primary : AppColors.trackingLineTodo,
            ),
          ),
        ],
      ],
    );
  }
}
