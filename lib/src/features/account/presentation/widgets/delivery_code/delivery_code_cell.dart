import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// One slot of the new-code editor. The border keeps its width and only its
/// colour moves: ink on the slot being typed, green once saved.
class DeliveryCodeCell extends StatelessWidget {
  const DeliveryCodeCell({
    super.key,
    required this.digit,
    required this.active,
    required this.saved,
  });

  static const double height = AppSize.s56;

  final String digit;
  final bool active;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final border = saved
        ? AppColors.primary
        : active
        ? AppColors.primaryText
        : AppColors.divider;
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.white : AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.r3),
        border: Border.all(color: border, width: AppSize.s2),
      ),
      child: Text(
        digit,
        style: AppTextStyles.displaySmall.copyWith(
          fontWeight: AppTextStyles.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
