import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';

/// One canned-reply pill.
class ImChatQuickReplyChip extends StatelessWidget {
  const ImChatQuickReplyChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      // Press feel on the pill; the InkWell keeps the tap and ripple.
      child: PressScale(
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => onTap(label),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              child: Text(
                label,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
