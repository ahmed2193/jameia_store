import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../core/responsive/app_size.dart';

/// A ring of brand colour spreading from the little launcher in the ready
/// demo — "here I am" — fading as [progress] goes to `1`; gone at both
/// ends.
class AssistantOnboardingPulseRing extends StatelessWidget {
  const AssistantOnboardingPulseRing({super.key, required this.progress});

  final double progress;

  static const double _growth = 1.2;
  static const double _alpha = 0.6;
  static const double _width = AppSize.s2;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return Transform.scale(
      scale: 1 + progress * _growth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: (1 - progress) * _alpha),
            width: _width,
          ),
        ),
      ),
    );
  }
}
