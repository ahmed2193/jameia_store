import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

class RefundOptionRow extends StatelessWidget {
  const RefundOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
            // Radio glyph — real Jameia refund-method icons with a drawn fallback.
            Image.asset(
              selected
                  ? JameiaAssets.refundMethodSelected
                  : JameiaAssets.refundMethodUnselected,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
