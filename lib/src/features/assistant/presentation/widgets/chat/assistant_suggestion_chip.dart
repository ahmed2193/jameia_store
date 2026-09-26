import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// One tappable suggestion / starter: an outlined pill, 48 dp tall to tap,
/// up to two lines at large text.
class AssistantSuggestionChip extends StatelessWidget {
  const AssistantSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: PressScale(
        onTap: onTap,
        enabled: onTap != null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SuiSize.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.brandTileBorder),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s14,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (glyph != null) ...[
                    Icon(
                      glyph,
                      size: AppSize.s16,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: AppSpacing.s6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subheadingMedium.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
