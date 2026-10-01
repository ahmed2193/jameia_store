import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// A card's text link ("View cart", "Track order"): brand-coloured label and
/// a directional chevron, with a 48 dp touch target.
class AssistantCardLink extends StatelessWidget {
  const AssistantCardLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.s48),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const HeroIcon(
                HeroIcons.chevronEnd,
                size: AppSize.s20,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
