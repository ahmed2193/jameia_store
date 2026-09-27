import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/responsive/app_size.dart';

/// The order's way to the door in the "more" demo: a short track that
/// fills from the start edge to [value].
class AssistantOnboardingProgressBar extends StatelessWidget {
  const AssistantOnboardingProgressBar({super.key, required this.value});

  /// Share of the way done, `0 → 1`.
  final double value;

  static const double _width = AppSize.s56;
  static const double _height = AppSize.s6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ColoredBox(
          color: AppColors.divider,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: const ColoredBox(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}
