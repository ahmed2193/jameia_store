import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_image.dart';

/// A rail pill that opens something (a category, a brand): round picture —
/// or [initial] when there is none — then the name. 48 dp tall.
class AssistantPillChip extends StatelessWidget {
  const AssistantPillChip({
    super.key,
    required this.label,
    required this.onTap,
    this.imageUrl = '',
    this.initial = '',
  });

  final String label;
  final String imageUrl;
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.white,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.brandTileBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.s48),
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s6,
              end: AppSpacing.s14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl.isNotEmpty)
                  HeroImage.circle(url: imageUrl, size: AppSize.s36)
                else
                  CircleAvatar(
                    radius: AppSize.s18,
                    backgroundColor: AppColors.brandLightBg,
                    child: Text(
                      initial,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
