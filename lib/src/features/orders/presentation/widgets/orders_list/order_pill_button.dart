import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

class OrderPillButton extends StatelessWidget {
  const OrderPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    // Bundle: e878cd / e11e8a — primary (filled) = #FFEA00 bg, border-radius 24dp,
    // height 48dp, padding 13dp/32dp; font Jameia-Bold 16dp w500 #222222.
    // Outline = white bg, border 1dp #00000014, same radius.
    final fg = filled ? AppColors.brandForeground : AppColors.primaryText;
    // Jameia brand yellow #FFE41F — closest token to bundle's #FFEA00
    final bg = filled ? AppColors.primary : AppColors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.r2), // 24dp (r2)
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r2),
        onTap: onPressed,
        child: Container(
          // Bundle: height 48dp, padding 13dp top/bottom, 32dp left/right (filled)
          // Outline uses same H shape with border
          height: AppSpacing.s48,
          // e11e8a: padding 13dp 32dp — height 48dp centres content vertically.
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s32,
          ),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.r2),
                  border: Border.all(
                    // Bundle: border 1dp solid #00000014 (overlayDivider)
                    color: AppColors.overlayDivider,
                  ),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: AppSpacing.s6),
              Text(
                label,
                // Bundle: e11e8a Jameia-Bold w500 16dp #222222
                style: AppTextStyles.headingMedium.copyWith(
                  color: fg,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
