import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/jameia_image.dart';

/// "Brand · Nestlé ›" / "Category · Basmati Rice ›": a labelled link to the
/// products of the brand or the category.
class PdpLinkRow extends StatelessWidget {
  const PdpLinkRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.imageUrl = '',
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty) ...[
              JameiaImage.circle(url: imageUrl, size: AppSize.s32),
              const SizedBox(width: AppSpacing.s8),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: AppSize.s18,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}
