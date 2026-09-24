import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/brand_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_image.dart';

/// One brand of the brands page: logo (or the brand's initial), name and the
/// backend's one-line description.
class BrandTile extends StatelessWidget {
  const BrandTile({super.key, required this.brand, required this.onTap});

  final BrandEntity brand;
  final VoidCallback onTap;

  static const double _logo = AppSize.s56;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          0,
          AppSpacing.s12,
          AppSpacing.s8,
        ),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: _logo,
              height: _logo,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.smallBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandTileBorder),
              ),
              child: brand.hasImage
                  ? JameiaImage.circle(url: brand.image, size: _logo)
                  : Text(
                      brand.initial,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  if (brand.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      brand.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: AppSize.s20,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
