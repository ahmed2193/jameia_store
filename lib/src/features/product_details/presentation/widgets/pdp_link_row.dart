import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_image.dart';

/// A flat labelled link to the products of the brand or the category: the
/// grey label over the ink name, and a chevron that follows the reading
/// direction.
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
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              if (imageUrl.isNotEmpty) ...[
                HeroImage.circle(url: imageUrl, size: AppSize.s40),
                const SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.itemTitleStrong.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const Icon(
                Icons.chevron_right_rounded,
                size: AppSize.s22,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
